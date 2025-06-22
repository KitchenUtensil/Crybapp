import Foundation
import Supabase
import Combine

@MainActor
class AuthService: ObservableObject {
    private let supabase = SupabaseConfig.shared
    
    @Published var currentUser: CrybUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        Task {
            await checkCurrentSession()
        }
    }
    
    func checkCurrentSession() async {
        isLoading = true
        
        guard let session = try? await supabase.auth.session else {
            self.isAuthenticated = false
            self.isLoading = false
            return
        }
        
        await fetchUserProfile(userId: session.user.id.uuidString)
        self.isAuthenticated = true
        self.isLoading = false
    }
    
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            await fetchUserProfile(userId: authResponse.user.id.uuidString)
        } catch {
            print(">>> SUPABASE SIGN-UP ERROR: \(error)")
            
            // Check if the error description indicates that the user already exists.
            if String(describing: error).contains("user_already_exists") {
                print("[AuthService] User already exists, attempting to sign in instead...")
                errorMessage = "Account already exists. Attempting to sign you in..."
                
                // Try to sign in with the same credentials
                do {
                    let signInResponse = try await supabase.auth.signIn(email: email, password: password)
                    await fetchUserProfile(userId: signInResponse.user.id.uuidString)
                    errorMessage = nil // Clear the error message since sign-in succeeded
                } catch {
                    print("[AuthService] >>> SIGN-IN ATTEMPT FAILED: \(error)")
                    errorMessage = "Account exists but password is incorrect. Please try signing in instead."
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("[AuthService] 1. Attempting to sign in with email: \(email)")
            let authResponse = try await supabase.auth.signIn(email: email, password: password)
            print("[AuthService] 2. Sign-in to Supabase successful for user ID: \(authResponse.user.id)")
            
            await fetchUserProfile(userId: authResponse.user.id.uuidString)
        } catch {
            print("[AuthService] >>> SUPABASE SIGN-IN ERROR: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func fetchUserProfile(userId: String) async {
        do {
            print("[AuthService] 3. Fetching profile from 'users' table for ID: \(userId)")
            let response: [CrybUser] = try await supabase
                .from("users")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            print("[AuthService] 4. Database query complete. Found \(response.count) matching users.")
            
            if let user = response.first {
                currentUser = user
                isAuthenticated = true
                print("[AuthService] 5. Profile found: \(user.displayName ?? "No Name"). Setting isAuthenticated = true.")
            } else {
                isAuthenticated = false
                errorMessage = "Could not find a profile for the logged-in user."
                print("[AuthService] 5. No profile found in 'users' table. Setting isAuthenticated = false.")
            }
        } catch {
            print("[AuthService] >>> ERROR FETCHING USER PROFILE: \(error)")
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
    }
    
    func updateProfile(name: String) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let updateData = UpdateUserRequest(displayName: name)
            let response: [CrybUser] = try await supabase
                .from("users")
                .update(updateData)
                .eq("id", value: userId)
                .execute()
                .value
            
            if let updatedUser = response.first {
                currentUser = updatedUser
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Profile Requests
private struct UpdateUserRequest: Encodable {
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
} 
 