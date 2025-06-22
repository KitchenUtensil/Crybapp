import SwiftUI

struct ChoresListView: View {
    @ObservedObject var choreService: ChoreService
    
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
                    ChoreRowView(chore: chore, choreService: choreService)
                }
            }
        }
        .navigationTitle("Chores")
        .navigationBarTitleDisplayMode(.large)
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
