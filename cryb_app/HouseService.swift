import Foundation
import Supabase
import Combine

@MainActor
class HouseService: ObservableObject {
    private let supabase = SupabaseConfig.shared
    
    @Published var currentHouse: House?
    @Published var houseMembers: [CrybUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // The user's list of houses. In this schema, it will only ever be one or zero.
    @Published var userHouses: [House] = []

    func createHouse(name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Get current user's ID
            let userId = try await supabase.auth.session.user.id
            
            // 2. Create the house object
            let newHouseRequest = CreateHouseRequest(
                name: name,
                code: generateInviteCode(),
                createdBy: userId
            )
            
            // 3. Insert the new house and get the created record
            let createdHouse: House = try await supabase
                .from("houses")
                .insert(newHouseRequest, returning: .representation)
                .select("id, name, code, created_at, created_by")
                .single()
                .execute()
                .value

            // 4. Update the user's house_id to automatically join the house
            await updateUserHouseId(userId: userId, houseId: createdHouse.id)
            
            // 5. Refresh local data
            self.currentHouse = createdHouse
            await fetchUserHouses()
            
        } catch {
            print(">>> HOUSE SERVICE ERROR: creating house: \\(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func joinHouse(inviteCode: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print(">>> JOIN HOUSE: Starting join process for code: \(inviteCode)")
            
            // 1. Get the current user's ID
            let userId = try await supabase.auth.session.user.id
            print(">>> JOIN HOUSE: Got user ID: \(userId)")

            // 2. Find the house by its invite code
            print(">>> JOIN HOUSE: Searching for house with code: \(inviteCode)")
            let houses: [House] = try await supabase
                .from("houses")
                .select("id, name, code, created_at, created_by")
                .eq("code", value: inviteCode)
                .limit(1) // We only need one
                .execute()
                .value
            
            print(">>> JOIN HOUSE: Found \(houses.count) houses")
            
            // 3. Check if we found exactly one house
            guard let houseToJoin = houses.first else {
                print(">>> JOIN HOUSE: No house found with code: \(inviteCode)")
                errorMessage = "Invalid invite code. Please try again."
                isLoading = false
                return
            }
            
            print(">>> JOIN HOUSE: Found house: \(houseToJoin.name) with ID: \(houseToJoin.id)")
            
            // 4. Update the user's house_id to join the house
            print(">>> JOIN HOUSE: Updating user's house_id")
            await updateUserHouseId(userId: userId, houseId: houseToJoin.id)

            // 5. Set the current house and update userHouses
            print(">>> JOIN HOUSE: Setting current house")
            self.currentHouse = houseToJoin
            self.userHouses = [houseToJoin]
            // await fetchUserHouses() // This will be handled by the view on dismiss
            
            print(">>> JOIN HOUSE: Successfully joined house")
            
        } catch {
            print(">>> HOUSE SERVICE ERROR: joining house: \(error)")
            print(">>> HOUSE SERVICE ERROR: Error type: \(type(of: error))")
            print(">>> HOUSE SERVICE ERROR: Localized description: \(error.localizedDescription)")
            errorMessage = "Invalid invite code or error joining house."
        }
        
        isLoading = false
    }

    func fetchUserHouses() async {
        print(">>> FETCH USER HOUSES: Starting fetch")
        guard let userId = try? await supabase.auth.session.user.id else { 
            print(">>> FETCH USER HOUSES: No user ID found")
            return 
        }
        print(">>> FETCH USER HOUSES: Got user ID: \(userId)")

        do {
            // A user can only be in one house, so we fetch their profile
            // and then use the house_id to fetch the associated house.
            print(">>> FETCH USER HOUSES: Fetching user profile")
            let user: CrybUser = try await supabase
                .from("users")
                .select("id, email, display_name, house_id, created_at")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            print(">>> FETCH USER HOUSES: User house_id: \(user.houseId?.description ?? "nil")")

            if let houseId = user.houseId {
                print(">>> FETCH USER HOUSES: Fetching house with ID: \(houseId)")
                let house: House = try await supabase
                    .from("houses")
                    .select("id, name, code, created_at, created_by")
                    .eq("id", value: houseId)
                    .single()
                    .execute()
                    .value
                print(">>> FETCH USER HOUSES: Successfully fetched house: \(house.name)")
                self.userHouses = [house]
                self.currentHouse = house
            } else {
                // User is not in a house
                print(">>> FETCH USER HOUSES: User not in any house")
                self.userHouses = []
                self.currentHouse = nil
            }
        } catch {
            print(">>> HOUSE SERVICE ERROR: fetching user house: \(error)")
            print(">>> HOUSE SERVICE ERROR: Error type: \(type(of: error))")
            print(">>> HOUSE SERVICE ERROR: Localized description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func updateUserHouseId(userId: UUID, houseId: UUID) async {
        do {
            let request = UpdateUserHouseRequest(houseId: houseId)
            try await supabase
                .from("users")
                .update(request)
                .eq("id", value: userId)
                .execute()
        } catch {
            print(">>> HOUSE SERVICE ERROR: updating user's house_id: \\(error)")
            errorMessage = "Failed to update user's house link."
        }
    }

    func getHouseMembers() async {
        guard let houseId = currentHouse?.id else { return }
        
        do {
            let members: [CrybUser] = try await supabase
                .from("users")
                .select()
                .eq("house_id", value: houseId)
                .execute()
                .value
            
            self.houseMembers = members
        } catch {
            print(">>> HOUSE SERVICE ERROR: fetching house members: \\(error)")
            errorMessage = error.localizedDescription
            self.houseMembers = []
        }
    }
    
    func setCurrentHouse(_ house: House) {
        currentHouse = house
        Task {
            await getHouseMembers()
        }
    }
    
    func leaveHouse() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userId = try await supabase.auth.session.user.id
            
            // Set the user's house_id to null
            let request = UpdateUserHouseRequest(houseId: nil)
            try await supabase
                .from("users")
                .update(request)
                .eq("id", value: userId)
                .execute()
            
            // Update local state
            self.currentHouse = nil
            self.userHouses = []
            self.houseMembers = []
            
        } catch {
            print(">>> HOUSE SERVICE ERROR: leaving house: \(error)")
            errorMessage = "Failed to leave house."
        }
        
        isLoading = false
    }
    
    private func generateInviteCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

private struct UpdateUserHouseRequest: Encodable {
    let houseId: UUID?

    enum CodingKeys: String, CodingKey {
        case houseId = "house_id"
    }
} 
 