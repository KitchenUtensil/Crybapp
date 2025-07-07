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
        
        let profileFound = await fetchUserProfile(userId: session.user.id.uuidString)
        if profileFound {
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
            self.errorMessage = "User profile not found. Please sign out and sign in again."
        }
        self.isLoading = false
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(displayName)]
            )
            
            // Try to fetch the user profile
            let profileFound = await fetchUserProfile(userId: authResponse.user.id.uuidString)
            
            // If profile not found, create it manually
            if !profileFound {
                print("[AuthService] Profile not found after sign-up, creating manually...")
                await createUserProfile(userId: authResponse.user.id.uuidString, email: email, displayName: displayName)
                // Try fetching again
                _ = await fetchUserProfile(userId: authResponse.user.id.uuidString)
            }
        } catch {
            print(">>> SUPABASE SIGN-UP ERROR: \(error)")
            
            // Check if the error description indicates that the user already exists.
            if String(describing: error).contains("user_already_exists") {
                print("[AuthService] User already exists, attempting to sign in instead...")
                errorMessage = "Account already exists. Attempting to sign you in..."
                
                // Try to sign in with the same credentials
                do {
                    let signInResponse = try await supabase.auth.signIn(email: email, password: password)
                    let profileFound = await fetchUserProfile(userId: signInResponse.user.id.uuidString)
                    
                    if !profileFound {
                        await createUserProfile(userId: signInResponse.user.id.uuidString, email: email, displayName: displayName)
                        _ = await fetchUserProfile(userId: signInResponse.user.id.uuidString)
                    }
                    
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
            
            let profileFound = await fetchUserProfile(userId: authResponse.user.id.uuidString)
            
            if !profileFound {
                print("[AuthService] Profile not found after sign-in, creating manually...")
                await createUserProfile(userId: authResponse.user.id.uuidString, email: email, displayName: nil)
                _ = await fetchUserProfile(userId: authResponse.user.id.uuidString)
            }
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
    
    private func fetchUserProfile(userId: String) async -> Bool {
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
                return true
            } else {
                isAuthenticated = false
                print("[AuthService] 5. No profile found in 'users' table.")
                return false
            }
        } catch {
            print("[AuthService] >>> ERROR FETCHING USER PROFILE: \(error)")
            errorMessage = error.localizedDescription
            isAuthenticated = false
            return false
        }
    }
    
    private func createUserProfile(userId: String, email: String, displayName: String?) async {
        do {
            print("[AuthService] Creating user profile for ID: \(userId)")
            let newUser = CreateUserRequest(
                id: userId,
                email: email,
                displayName: displayName ?? "User"
            )
            
            let response: [CrybUser] = try await supabase
                .from("users")
                .insert(newUser)
                .execute()
                .value
            
            if let createdUser = response.first {
                print("[AuthService] Successfully created user profile: \(createdUser.displayName ?? "No Name")")
            }
        } catch {
            print("[AuthService] >>> ERROR CREATING USER PROFILE: \(error)")
            errorMessage = "Failed to create user profile: \(error.localizedDescription)"
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
    
    func changePassword(currentPassword: String, newPassword: String) async -> String? {
        // Supabase requires re-authentication before changing password
        guard let email = currentUser?.email else {
            return "No user email found."
        }
        do {
            // Re-authenticate
            _ = try await supabase.auth.signIn(email: email, password: currentPassword)
            // Change password
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            return nil // Success
        } catch {
            print(">>> CHANGE PASSWORD ERROR: \(error)")
            return error.localizedDescription
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

private struct CreateUserRequest: Encodable {
    let id: String
    let email: String
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
    }
} 
 
