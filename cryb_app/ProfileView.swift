import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String = ""
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    // Password change states
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var isChangingPassword = false
    @State private var passwordChangeSuccess = false
    @State private var passwordChangeError: String?
    @State private var isLoadingProfile = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoadingProfile {
                    VStack(spacing: 24) {
                        ProgressView()
                        Text("Loading profile...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    VStack(alignment: .leading, spacing: 28) {
                        // Profile Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Profile")
                                .font(.title2).bold()
                            TextField("Display Name", text: $displayName)
                                .font(.title3.weight(.medium))
                                .disabled(!isEditing)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            if showSuccess {
                                Text("Profile updated!")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            HStack(spacing: 12) {
                                if isEditing {
                                    Button(action: saveProfile) {
                                        Text(isSaving ? "Saving..." : "Save")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .disabled(isSaving || displayName.isEmpty)
                                } else {
                                    Button(action: { isEditing = true }) {
                                        Text("Edit")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemGray5))
                                            .foregroundColor(.blue)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Change Password
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Change Password")
                                .font(.headline)
                            if authService.currentUser == nil {
                                Text("User not loaded. Please sign out and sign in again.")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            SecureField("Current Password", text: $currentPassword)
                                .textContentType(.password)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .disabled(authService.currentUser == nil)
                            SecureField("New Password", text: $newPassword)
                                .textContentType(.newPassword)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .disabled(authService.currentUser == nil)
                            SecureField("Confirm New Password", text: $confirmNewPassword)
                                .textContentType(.newPassword)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .disabled(authService.currentUser == nil)
                            if let pwError = passwordChangeError {
                                Text(pwError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            if passwordChangeSuccess {
                                Text("Password changed successfully!")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            Button(action: changePassword) {
                                Text(isChangingPassword ? "Changing..." : "Change Password")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(isChangingPassword || currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty || authService.currentUser == nil)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if let user = authService.currentUser {
                    displayName = user.displayName ?? ""
                    isLoadingProfile = false
                } else {
                    // Try to reload user if not loaded
                    Task {
                        await authService.checkCurrentSession()
                        if let user = authService.currentUser {
                            displayName = user.displayName ?? ""
                        }
                        isLoadingProfile = false
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        errorMessage = nil
        showSuccess = false
        Task {
            await authService.updateProfile(name: displayName)
            isSaving = false
            if let error = authService.errorMessage {
                errorMessage = error
            } else {
                showSuccess = true
                isEditing = false
            }
        }
    }
    
    private func changePassword() {
        passwordChangeError = nil
        passwordChangeSuccess = false
        guard authService.currentUser != nil else {
            passwordChangeError = "User not loaded. Please sign out and sign in again."
            return
        }
        guard newPassword == confirmNewPassword else {
            passwordChangeError = "New passwords do not match."
            return
        }
        isChangingPassword = true
        Task {
            let result = await authService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            isChangingPassword = false
            if let error = result {
                passwordChangeError = error
            } else {
                passwordChangeSuccess = true
                currentPassword = ""
                newPassword = ""
                confirmNewPassword = ""
            }
        }
    }
} 