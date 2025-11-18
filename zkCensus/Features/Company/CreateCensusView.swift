import SwiftUI

struct CreateCensusView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var enableLocation = false
    @State private var minAge = 18

    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Census Details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Requirements") {
                    Stepper("Minimum Age: \(minAge)", value: $minAge, in: 0...100)

                    Toggle("Collect Location Data", isOn: $enableLocation)
                }

                Section {
                    InfoBox(
                        icon: "info.circle.fill",
                        title: "About Census",
                        message: "A census allows you to verify members while maintaining their privacy. Members submit zero-knowledge proofs that reveal only aggregate statistics.",
                        color: .blue
                    )
                }

                Section("Privacy Settings") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Age ranges only (not exact age)")
                                .font(.caption)
                        }

                        if enableLocation {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                Text("Continent only (not exact country)")
                                    .font(.caption)
                            }
                        }

                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("No personal information collected")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Create Census")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCensus()
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isCreating {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Creating census...")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && description.count >= 10
    }

    private func createCensus() {
        guard let walletAddress = authManager.currentUser?.walletAddress else {
            errorMessage = "Wallet not connected"
            showError = true
            return
        }

        isCreating = true

        Task {
            do {
                // Sign message for authorization
                let message = "Create census: \(name)"
                let signature = try await SolanaService.shared.signMessage(message)

                // Create census request
                let request = CreateCensusRequest(
                    name: name,
                    description: description,
                    enableLocation: enableLocation,
                    minAge: minAge,
                    creatorPublicKey: walletAddress,
                    signature: signature
                )

                // Submit to backend
                _ = try await APIClient.shared.createCensus(request)

                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateCensusView()
            .environmentObject(AuthenticationManager.shared)
    }
}
