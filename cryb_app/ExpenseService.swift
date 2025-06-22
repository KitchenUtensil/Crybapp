import Foundation
import Supabase
import Combine

@MainActor
class ExpenseService: ObservableObject {
    private let supabase = SupabaseConfig.shared
    
    @Published var expenses: [Expense] = []
    @Published var recentExpenses: [Expense] = []
    @Published var balanceSummary: BalanceSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchExpenses(houseId: String) async {
        isLoading = true
        
        do {
            let response: [Expense] = try await supabase
                .from("expenses")
                .select()
                .eq("house_id", value: houseId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            expenses = response
            recentExpenses = Array(response.prefix(5))
            await calculateBalance(houseId: houseId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createExpense(title: String, amount: Double, description: String?, category: String?, sharedWith: [String], houseId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            
            let newExpense = CreateExpenseRequest(
                title: title,
                amount: amount,
                description: description,
                paidBy: userId,
                houseId: houseId,
                category: category,
                sharedWith: sharedWith
            )
            
            let response: [Expense] = try await supabase
                .from("expenses")
                .insert(newExpense)
                .execute()
                .value
            
            if let expense = response.first {
                expenses.insert(expense, at: 0)
                recentExpenses = Array(expenses.prefix(5))
                await calculateBalance(houseId: houseId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateExpense(_ expense: Expense, title: String, amount: Double, description: String?, category: String?, sharedWith: [String]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updateData = UpdateExpenseRequest(
                title: title,
                amount: amount,
                description: description,
                category: category,
                sharedWith: sharedWith
            )
            
            let response: [Expense] = try await supabase
                .from("expenses")
                .update(updateData)
                .eq("id", value: expense.id)
                .execute()
                .value
            
            if let updatedExpense = response.first {
                if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                    expenses[index] = updatedExpense
                }
                recentExpenses = Array(expenses.prefix(5))
                await calculateBalance(houseId: expense.houseId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteExpense(_ expense: Expense) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase
                .from("expenses")
                .delete()
                .eq("id", value: expense.id)
                .execute()
            
            expenses.removeAll { $0.id == expense.id }
            recentExpenses = Array(expenses.prefix(5))
            await calculateBalance(houseId: expense.houseId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func calculateBalance(houseId: String) async {
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            
            // Get all expenses for the house
            let allExpenses: [Expense] = try await supabase
                .from("expenses")
                .select()
                .eq("house_id", value: houseId)
                .execute()
                .value
            
            var youOwe: Double = 0
            var youAreOwed: Double = 0
            
            for expense in allExpenses {
                let amount = expense.amount
                let sharedWith = expense.sharedWith ?? []
                let shareCount = sharedWith.count + 1 // Including the person who paid
                let shareAmount = amount / Double(shareCount)
                
                if expense.paidBy == userId {
                    // You paid for this expense
                    if sharedWith.contains(userId) {
                        // You're also sharing in it
                        youAreOwed += amount - shareAmount
                    } else {
                        // You paid for others
                        youAreOwed += amount - shareAmount
                    }
                } else if sharedWith.contains(userId) {
                    // Someone else paid, but you're sharing
                    youOwe += shareAmount
                }
            }
            
            balanceSummary = BalanceSummary(
                youOwe: youOwe,
                youAreOwed: youAreOwed,
                netBalance: youAreOwed - youOwe
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getExpenseCategories() -> [String] {
        return ["General", "Food", "Transport", "Utilities", "Entertainment", "Shopping", "Other"]
    }
} 
 