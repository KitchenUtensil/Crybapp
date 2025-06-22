import SwiftUI

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
                if houseService.userHouses.isEmpty {
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
    CreateHouseView()
        .environmentObject(HouseService())
}
 