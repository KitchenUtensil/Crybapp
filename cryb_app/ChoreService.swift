import Foundation
import Supabase
import Combine

@MainActor
class ChoreService: ObservableObject {
    private let supabase = SupabaseConfig.shared
    
    @Published var chores: [Chore] = []
    @Published var upcomingChores: [Chore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchChores(houseId: String) async {
        isLoading = true
        
        do {
            let response: [Chore] = try await supabase
                .from("chores")
                .select()
                .eq("house_id", value: houseId)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            chores = response
            upcomingChores = response.filter { !$0.isCompleted && ($0.dueDate == nil || $0.dueDate! > Date()) }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createChore(title: String, description: String?, dueDate: Date?, assignedUserId: String?, recurrence: RecurrenceType, points: Int?, houseId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            
            let request = CreateChoreRequest(
                title: title,
                description: description ?? "",
                dueDate: dueDate?.ISO8601String() ?? "",
                assignedUserId: assignedUserId ?? "",
                houseId: houseId,
                createdBy: userId,
                recurrence: recurrence,
                points: points ?? 0,
                isCompleted: false
            )
            
            let response: [Chore] = try await supabase
                .from("chores")
                .insert(request)
                .execute()
                .value
            
            if let chore = response.first {
                chores.append(chore)
                if !chore.isCompleted && (chore.dueDate == nil || chore.dueDate! > Date()) {
                    upcomingChores.append(chore)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateChore(_ chore: Chore, isCompleted: Bool) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = UpdateChoreCompletionRequest(isCompleted: isCompleted)
            
            let response: [Chore] = try await supabase
                .from("chores")
                .update(request)
                .eq("id", value: chore.id)
                .execute()
                .value
            
            if let updatedChore = response.first {
                if let index = chores.firstIndex(where: { $0.id == chore.id }) {
                    chores[index] = updatedChore
                }
                
                // Update upcoming chores
                upcomingChores.removeAll { $0.id == chore.id }
                if !updatedChore.isCompleted && (updatedChore.dueDate == nil || updatedChore.dueDate! > Date()) {
                    upcomingChores.append(updatedChore)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func assignChore(_ chore: Chore, to userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = UpdateChoreAssignmentRequest(assignedUserId: userId)
            
            let response: [Chore] = try await supabase
                .from("chores")
                .update(request)
                .eq("id", value: chore.id)
                .execute()
                .value
            
            if let updatedChore = response.first {
                if let index = chores.firstIndex(where: { $0.id == chore.id }) {
                    chores[index] = updatedChore
                }
                
                if let upcomingIndex = upcomingChores.firstIndex(where: { $0.id == chore.id }) {
                    upcomingChores[upcomingIndex] = updatedChore
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteChore(_ chore: Chore) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase
                .from("chores")
                .delete()
                .eq("id", value: chore.id)
                .execute()
            
            chores.removeAll { $0.id == chore.id }
            upcomingChores.removeAll { $0.id == chore.id }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
 