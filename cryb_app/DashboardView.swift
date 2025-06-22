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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // House Header
                    houseHeader
                    
                    // Balance Summary
                    if let balance = expenseService.balanceSummary {
                        balanceSummaryCard(balance)
                    }
                    
                    // Upcoming Chores
                    upcomingChoresSection
                    
                    // Recent Expenses
                    recentExpensesSection
                    
                    // Pinned Notes
                    pinnedNotesSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if houseService.currentHouse == nil {
                            Button("Create House") {
                                showingCreateHouse = true
                            }
                            Button("Join House") {
                                showingJoinHouse = true
                            }
                        } else {
                            Button("Switch House") {
                                showingHouseSelector = true
                            }
                            Button("Leave House") {
                                showingLeaveHouseConfirmation = true
                            }
                            .disabled(houseService.isLoading)
                        }
                        Divider()
                        Button("Sign Out", role: .destructive) {
                            Task {
                                await authService.signOut()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreateHouse) {
                CreateHouseView()
                    .environmentObject(houseService)
                    .environmentObject(authService)
                    .environmentObject(choreService)
                    .environmentObject(expenseService)
                    .environmentObject(noteService)
            }
            .sheet(isPresented: $showingJoinHouse, onDismiss: {
                if houseService.currentHouse != nil {
                    Task {
                        await loadDashboardData()
                    }
                }
            }) {
                JoinHouseView()
                    .environmentObject(houseService)
                    .environmentObject(authService)
                    .environmentObject(choreService)
                    .environmentObject(expenseService)
                    .environmentObject(noteService)
            }
            .sheet(isPresented: $showingHouseSelector) {
                HouseSelectorView()
                    .environmentObject(houseService)
                    .environmentObject(authService)
                    .environmentObject(choreService)
                    .environmentObject(expenseService)
                    .environmentObject(noteService)
            }
            .confirmationDialog(
                "Leave House",
                isPresented: $showingLeaveHouseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Leave House", role: .destructive) {
                    Task {
                        await houseService.leaveHouse()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to leave this house? You'll need to be invited back to rejoin.")
            }
            .onAppear {
                Task {
                    if houseService.currentHouse == nil {
                        await houseService.fetchUserHouses()
                    }
                    await loadDashboardData()
                }
            }
            .refreshable {
                await loadDashboardData()
            }
        }
    }
    
    private var houseHeader: some View {
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
    
    private func balanceSummaryCard(_ balance: BalanceSummary) -> some View {
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
    
    private var upcomingChoresSection: some View {
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
            
            if choreService.upcomingChores.isEmpty {
                Text("No upcoming chores")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(choreService.upcomingChores.prefix(3))) { chore in
                    ChoreRowView(chore: chore, choreService: choreService)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var recentExpensesSection: some View {
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
    
    private var pinnedNotesSection: some View {
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
    
    private func loadDashboardData() async {
        guard let currentHouse = houseService.currentHouse else { return }
        
        await choreService.fetchChores(houseId: currentHouse.id.uuidString)
        await expenseService.fetchExpenses(houseId: currentHouse.id.uuidString)
        await noteService.fetchNotes(houseId: currentHouse.id.uuidString)
    }
}

struct ChoreRowView: View {
    let chore: Chore
    @ObservedObject var choreService: ChoreService
    
    var body: some View {
        HStack {
            Button(action: {
                Task {
                    // await choreService.updateChore(chore, isCompleted: !chore.isCompleted)
                }
            }) {
                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(chore.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(chore.isCompleted)
                
                if let dueDate = chore.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let points = chore.points, points > 0 {
                Text("\(points) pts")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
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
 