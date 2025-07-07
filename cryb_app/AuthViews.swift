import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showSignUp = false
    @State private var formErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header - Stays the same
                VStack(spacing: 10) {
                    Image(systemName: "house.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Welcome to cryb")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(showSignUp ? "Create an account to get started" : "Sign in to manage your household")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                // Animated Form Section
                VStack(spacing: 20) {
                    if showSignUp {
                        VStack(spacing: 20) {
                            TextField("Display Name", text: $displayName)
                            TextField("Email", text: $email)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            SecureField("Password", text: $password)
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    } else {
                        VStack(spacing: 20) {
                            TextField("Email", text: $email)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            SecureField("Password", text: $password)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())

                // Error Message
                if let error = formErrorMessage ?? authService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                // Action Button
                VStack {
                    if showSignUp {
                        Button(action: signUp) {
                            HStack {
                                if authService.isLoading { ProgressView().progressViewStyle(.circular) }
                                Text("Sign Up")
                            }
                        }
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty || displayName.isEmpty || confirmPassword.isEmpty)
                    } else {
                        Button(action: signIn) {
                             HStack {
                                if authService.isLoading { ProgressView().progressViewStyle(.circular) }
                                Text("Sign In")
                            }
                        }
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.headline.weight(.semibold))

                // Toggle Button
                Button(action: toggleForm) {
                    Text(showSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                }
                .padding(.top)

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func toggleForm() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSignUp.toggle()
        }
        // Clear fields and errors when toggling
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        formErrorMessage = nil
        authService.errorMessage = nil
    }

    private func signIn() {
        formErrorMessage = nil
        Task {
            await authService.signIn(email: email, password: password)
        }
    }

    private func signUp() {
        if password != confirmPassword {
            formErrorMessage = "Passwords do not match."
            return
        }
        
        formErrorMessage = nil
        Task {
            await authService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
} 
