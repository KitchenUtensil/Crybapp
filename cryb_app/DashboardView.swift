import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var houseService: HouseService
    @EnvironmentObject private var choreService: ChoreService
    @EnvironmentObject private var expenseService: ExpenseService
    @EnvironmentObject private var noteService: NoteService
    
    @State private var showingHouseSelector = false
    @State private var showingCreateHouse = false
    @State private var showingJoinHouse = false
    @State private var showingLeaveHouseConfirmation = false
    @State private var showingProfile = false
    @State private var showingHouseOnboarding = false
    
    var body: some View {
        DashboardMainView(
            showingHouseSelector: $showingHouseSelector,
            showingCreateHouse: $showingCreateHouse,
            showingJoinHouse: $showingJoinHouse,
            showingLeaveHouseConfirmation: $showingLeaveHouseConfirmation,
            showingProfile: $showingProfile,
            showingHouseOnboarding: $showingHouseOnboarding
        )
        .environmentObject(authService)
        .environmentObject(houseService)
        .environmentObject(choreService)
        .environmentObject(expenseService)
        .environmentObject(noteService)
    }
}

struct DashboardMainView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var houseService: HouseService
    @EnvironmentObject private var choreService: ChoreService
    @EnvironmentObject private var expenseService: ExpenseService
    @EnvironmentObject private var noteService: NoteService
    
    @Binding var showingHouseSelector: Bool
    @Binding var showingCreateHouse: Bool
    @Binding var showingJoinHouse: Bool
    @Binding var showingLeaveHouseConfirmation: Bool
    @Binding var showingProfile: Bool
    @Binding var showingHouseOnboarding: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                DashboardSectionsView(
                    houseService: houseService,
                    choreService: choreService,
                    expenseService: expenseService,
                    noteService: noteService,
                    showingLeaveHouseConfirmation: $showingLeaveHouseConfirmation,
                    showingHouseSelector: $showingHouseSelector
                )
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.crop.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await authService.signOut()
                        }
                    }) {
                        Image(systemName: "arrow.backward.square")
                    }
                    .accessibilityLabel("Sign Out")
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingHouseSelector) {
                HouseSelectorView()
                    .environmentObject(houseService)
            }
            .sheet(isPresented: $showingCreateHouse) {
                CreateHouseView()
                    .environmentObject(houseService)
            }
            .sheet(isPresented: $showingJoinHouse) {
                JoinHouseView()
                    .environmentObject(houseService)
            }
            .fullScreenCover(isPresented: $showingHouseOnboarding, onDismiss: {
                // No-op: user should not be able to dismiss unless in a house
            }) {
                HouseOnboardingView()
                    .environmentObject(houseService)
                    .environmentObject(authService)
                    .environmentObject(choreService)
                    .environmentObject(expenseService)
                    .environmentObject(noteService)
            }
            .confirmationDialog(
                "Are you sure you want to leave the house?",
                isPresented: $showingLeaveHouseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Leave House", role: .destructive) {
                    Task {
                        await houseService.leaveHouse()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                Task {
                    if houseService.currentHouse == nil {
                        await houseService.fetchUserHouses()
                    }
                    await loadDashboardData()
                    await MainActor.run {
                        showingHouseOnboarding = houseService.currentHouse == nil
                    }
                }
            }
            .onChange(of: houseService.currentHouse) { oldValue, newValue in
                if newValue != nil {
                    showingHouseOnboarding = false
                }
            }
        }
    }
    
    private func loadDashboardData() async {
        guard let houseId = houseService.currentHouse?.id.uuidString else { return }
        await choreService.fetchChores(houseId: houseId)
        await expenseService.fetchExpenses(houseId: houseId)
        await noteService.fetchNotes(houseId: houseId)
    }
}

struct DashboardSectionsView: View {
    @ObservedObject var houseService: HouseService
    @ObservedObject var choreService: ChoreService
    @ObservedObject var expenseService: ExpenseService
    @ObservedObject var noteService: NoteService
    @Binding var showingLeaveHouseConfirmation: Bool
    @Binding var showingHouseSelector: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HouseHeaderView(
                houseService: houseService,
                showingLeaveHouseConfirmation: $showingLeaveHouseConfirmation,
                showingHouseSelector: $showingHouseSelector
            )
            BalanceSummarySectionView(expenseService: expenseService)
            UpcomingChoresSectionView(choreService: choreService)
            RecentExpensesSectionView(expenseService: expenseService)
            PinnedNotesSectionView(noteService: noteService)
        }
    }
}

struct HouseHeaderView: View {
    @ObservedObject var houseService: HouseService
    @Binding var showingLeaveHouseConfirmation: Bool
    @Binding var showingHouseSelector: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let currentHouse = houseService.currentHouse {
                HStack {
                    VStack(alignment: .leading) {
                        Text(currentHouse.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Invite Code: \(currentHouse.code)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button("Copy") {
                            UIPasteboard.general.string = currentHouse.code
                        }
                        .buttonStyle(.bordered)
                        Button("Leave House") {
                            showingLeaveHouseConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(houseService.isLoading)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No House Selected")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Create or join a house to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BalanceSummarySectionView: View {
    @ObservedObject var expenseService: ExpenseService
    var body: some View {
        if let balance = expenseService.balanceSummary {
            VStack(spacing: 12) {
                Text("Balance Summary")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You Owe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(balance.youOwe, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 4) {
                        Text("Net Balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(balance.netBalance, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(balance.netBalance >= 0 ? .green : .red)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("You're Owed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(balance.youAreOwed, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct UpcomingChoresSectionView: View {
    @ObservedObject var choreService: ChoreService
    
    // Use a static DateFormatter to avoid recreating it every time
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        let upcomingChores = choreService.chores.filter { chore in
            guard !chore.completed else { return false }
            guard let dueDateString = chore.dueDate, let dueDate = UpcomingChoresSectionView.dateFormatter.date(from: dueDateString) else {
                return true // If no due date, consider it upcoming
            }
            return dueDate > Date()
        }
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Chores")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") {
                    ChoresListView(choreService: choreService)
                }
                .font(.caption)
            }
            if upcomingChores.isEmpty {
                Text("No upcoming chores")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(upcomingChores.prefix(3))) { chore in
                    ChoreRowView(chore: chore, choreService: choreService)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecentExpensesSectionView: View {
    @ObservedObject var expenseService: ExpenseService
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") {
                    ExpensesListView(expenseService: expenseService)
                }
                .font(.caption)
            }
            if expenseService.recentExpenses.isEmpty {
                Text("No recent expenses")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(expenseService.recentExpenses.prefix(3))) { expense in
                    ExpenseRowView(expense: expense)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PinnedNotesSectionView: View {
    @ObservedObject var noteService: NoteService
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pinned Notes")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") {
                    NotesListView(noteService: noteService)
                }
                .font(.caption)
            }
            if noteService.pinnedNotes.isEmpty {
                Text("No pinned notes")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(noteService.pinnedNotes.prefix(3))) { note in
                    NoteRowView(note: note, noteService: noteService)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let category = expense.category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("$\(expense.amount, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct NoteRowView: View {
    let note: Note
    @ObservedObject var noteService: NoteService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await noteService.togglePinNote(note)
                    }
                }) {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(note.isPinned ? .orange : .gray)
                }
            }
            
            Text(note.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
} 
 
