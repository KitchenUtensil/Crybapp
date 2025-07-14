import Foundation
import Supabase
import Combine

@MainActor
class ChoreService: ObservableObject {
    private let supabase = SupabaseConfig.shared
    
    @Published var chores: [Chore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchChores(houseId: String) async {
        isLoading = true
        print("[ChoreService] fetchChores for houseId: \(houseId)")
        do {
            let chores: [Chore] = try await supabase
                .from("chores")
                .select()
                .eq("house_id", value: houseId)
                .order("due_date", ascending: true)
                .execute()
                .value
            print("[ChoreService] fetched chores: \(chores)")
            self.chores = chores
        } catch {
            errorMessage = error.localizedDescription
            print("[ChoreService] fetch error: \(error)")
        }
        isLoading = false
    }
    
    func createChore(title: String, assignedTo: String?, dueDate: String?, houseId: String, completed: Bool = false) async {
        isLoading = true
        errorMessage = nil
        do {
            let newChore = CreateChoreRequest(
                title: title,
                dueDate: dueDate,
                assignedTo: assignedTo,
                houseId: houseId,
                completed: completed
            )
            let response: [Chore] = try await supabase
                .from("chores")
                .insert([newChore])
                .select()
                .execute()
                .value
            if let created = response.first {
                chores.append(created)
            }
            // Always refetch after create
            await fetchChores(houseId: houseId)
        } catch {
            errorMessage = error.localizedDescription
            print("[ChoreService] Failed to create chore: \(error)")
        }
        isLoading = false
    }
    
    func updateChore(_ chore: Chore) async {
        isLoading = true
        errorMessage = nil
        do {
            let updateData = UpdateChoreRequest(
                title: chore.title,
                dueDate: chore.dueDate,
                assignedTo: chore.assignedTo,
                completed: chore.completed
            )
            let response: [Chore] = try await supabase
                .from("chores")
                .update(updateData)
                .eq("id", value: chore.id)
                .select()
                .execute()
                .value
            if let updated = response.first, let idx = chores.firstIndex(where: { $0.id == updated.id }) {
                chores[idx] = updated
            }
            // Always refetch after update
            await fetchChores(houseId: chore.houseId)
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
            // Always refetch after delete
            await fetchChores(houseId: chore.houseId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
 
