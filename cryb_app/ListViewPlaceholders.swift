import SwiftUI

struct ChoresListView: View {
    @ObservedObject var choreService: ChoreService
    @EnvironmentObject var houseService: HouseService
    @EnvironmentObject var authService: AuthService
    @State private var showingChoreSheet = false
    @State private var editingChore: Chore? = nil
    
    var body: some View {
        VStack {
            if choreService.chores.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checklist")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Chores")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create your first chore to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(choreService.chores) { chore in
                    Button {
                        editingChore = chore
                        showingChoreSheet = true
                    } label: {
                        ChoreRowView(chore: chore, choreService: choreService)
                    }
                }
            }
        }
        .navigationTitle("Chores")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    editingChore = nil
                    showingChoreSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingChoreSheet) {
            if let houseId = houseService.currentHouse?.id.uuidString,
               let userId = authService.currentUser?.id.uuidString {
                ChoreEditView(
                    choreService: choreService,
                    houseId: houseId,
                    userId: userId,
                    chore: editingChore
                )
            }
        }
    }
}

struct ChoreEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var choreService: ChoreService
    var houseId: String
    var userId: String
    var chore: Chore? // nil for create, non-nil for edit

    @State private var title: String = ""
    @State private var dueDate: String = ""
    @State private var completed: Bool = false

    var isEdit: Bool { chore != nil }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chore Details")) {
                    TextField("Title", text: $title)
                    TextField("Due Date (YYYY-MM-DD)", text: $dueDate)
                    if isEdit {
                        Toggle("Completed", isOn: $completed)
                    }
                }
                if isEdit {
                    Button("Delete Chore", role: .destructive) {
                        Task {
                            if let chore = chore {
                                await choreService.deleteChore(chore)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEdit ? "Edit Chore" : "New Chore")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEdit ? "Save" : "Add") {
                        Task {
                            if isEdit, var chore = chore {
                                chore = Chore(
                                    id: chore.id,
                                    title: title,
                                    dueDate: dueDate,
                                    completed: completed,
                                    assignedTo: chore.assignedTo,
                                    houseId: chore.houseId,
                                    createdAt: chore.createdAt
                                )
                                await choreService.updateChore(chore)
                            } else {
                                print("[ChoreEditView] Creating chore with title: \(title)")
                                await choreService.createChore(
                                    title: title,
                                    assignedTo: userId.isEmpty ? nil : userId,
                                    dueDate: dueDate.isEmpty ? nil : dueDate,
                                    houseId: houseId,
                                    completed: completed
                                )
                            }
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if let chore = chore {
                title = chore.title
                dueDate = chore.dueDate ?? ""
                completed = chore.completed
            }
        }
    }
}

struct ChoreRowView: View {
    let chore: Chore
    @ObservedObject var choreService: ChoreService
    
    var body: some View {
        HStack {
            Button(action: {
                Task {
                    let updatedChore = Chore(
                        id: chore.id,
                        title: chore.title,
                        dueDate: chore.dueDate,
                        completed: !chore.completed,
                        assignedTo: chore.assignedTo,
                        houseId: chore.houseId,
                        createdAt: chore.createdAt
                    )
                    await choreService.updateChore(updatedChore)
                }
            }) {
                Image(systemName: chore.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(chore.completed ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(chore.completed)
                
                if let dueDate = chore.dueDate, !dueDate.isEmpty {
                    Text(dueDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ExpensesListView: View {
    @ObservedObject var expenseService: ExpenseService
    
    var body: some View {
        VStack {
            if expenseService.expenses.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Expenses")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Add your first expense to track spending")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(expenseService.expenses) { expense in
                    ExpenseRowView(expense: expense)
                }
            }
        }
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct NotesListView: View {
    @ObservedObject var noteService: NoteService
    
    var body: some View {
        VStack {
            if noteService.notes.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "note.text")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Notes")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create your first note to share information")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(noteService.notes) { note in
                    NoteRowView(note: note, noteService: noteService)
                }
            }
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        ChoresListView(choreService: ChoreService())
    }
} 
