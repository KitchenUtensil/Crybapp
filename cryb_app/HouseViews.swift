import SwiftUI

// MARK: - House Onboarding View (New)
struct HouseOnboardingView: View {
    @EnvironmentObject var houseService: HouseService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var expenseService: ExpenseService
    @EnvironmentObject var noteService: NoteService
    
    @State private var showingCreateHouse = false
    @State private var showingJoinHouse = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Welcome Header
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to cryb!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Join an existing house or create a new one to get started with your household management.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showingJoinHouse = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.badge.gearshape")
                                .font(.title2)
                            Text("Join Existing House")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingCreateHouse = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                            Text("Create New House")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Sign Out Option
                Button("Sign Out") {
                    Task {
                        await authService.signOut()
                    }
                }
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreateHouse) {
            CreateHouseView()
                .environmentObject(houseService)
                .environmentObject(authService)
                .environmentObject(choreService)
                .environmentObject(expenseService)
                .environmentObject(noteService)
        }
        .sheet(isPresented: $showingJoinHouse) {
            JoinHouseView()
                .environmentObject(houseService)
                .environmentObject(authService)
                .environmentObject(choreService)
                .environmentObject(expenseService)
                .environmentObject(noteService)
        }
    }
}

struct CreateHouseView: View {
    @EnvironmentObject var houseService: HouseService
    @State private var houseName = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Text("Create House")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            VStack(spacing: 10) {
                Image(systemName: "house.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Create New House")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Set up a new household for you and your housemates")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("House Name")
                    .font(.headline)
                TextField("Enter house name", text: $houseName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if let errorMessage = houseService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await houseService.createHouse(name: houseName)
                    if houseService.currentHouse != nil {
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            }) {
                HStack {
                    if houseService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text("Create House")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(houseService.isLoading || houseName.isEmpty)
            
            Spacer()
        }
        .padding()
    }
}

struct JoinHouseView: View {
    @EnvironmentObject var houseService: HouseService
    @State private var inviteCode = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Text("Join House")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            VStack(spacing: 10) {
                Image(systemName: "person.2.badge.gearshape")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Join House")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter the invite code to join an existing household")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Invite Code")
                    .font(.headline)
                TextField("Enter 6-digit code", text: $inviteCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.characters)
            }
            
            if let errorMessage = houseService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await houseService.joinHouse(inviteCode: inviteCode.uppercased())
                    if houseService.currentHouse != nil {
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            }) {
                HStack {
                    if houseService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text("Join House")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(houseService.isLoading || inviteCode.isEmpty || inviteCode.count != 6)
            
            Spacer()
        }
        .padding()
    }
}

struct HouseSelectorView: View {
    @EnvironmentObject var houseService: HouseService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let currentHouse = houseService.currentHouse {
                    VStack(spacing: 20) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("You are already in a house!")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("You can only be in one house at a time. Leave your current house to join or create another.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if houseService.userHouses.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "house")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Houses")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("You haven't joined any houses yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(houseService.userHouses) { house in
                        Button(action: {
                            houseService.setCurrentHouse(house)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(house.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Invite Code: \(house.code)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if houseService.currentHouse?.id == house.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Select House")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await houseService.fetchUserHouses()
                }
            }
        }
    }
}

#Preview {
    HouseOnboardingView()
        .environmentObject(HouseService())
        .environmentObject(AuthService())
        .environmentObject(ChoreService())
        .environmentObject(ExpenseService())
        .environmentObject(NoteService())
}
 