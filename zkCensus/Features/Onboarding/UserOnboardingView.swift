import SwiftUI

struct UserOnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Get Started")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Connect your Solana wallet to start creating zero-knowledge proofs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)

                // How it Works
                VStack(alignment: .leading, spacing: 20) {
                    Text("How it works")
                        .font(.title2)
                        .fontWeight(.semibold)

                    StepView(
                        number: 1,
                        title: "Connect Wallet",
                        description: "Link your Solana wallet for secure authentication"
                    )

                    StepView(
                        number: 2,
                        title: "Scan Passport",
                        description: "Use your camera or NFC to scan your passport"
                    )

                    StepView(
                        number: 3,
                        title: "Generate Proof",
                        description: "Create a zero-knowledge proof on your device"
                    )

                    StepView(
                        number: 4,
                        title: "Share Securely",
                        description: "Share proofs with companies while keeping your data private"
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)

                // Privacy Guarantee
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                            .font(.title)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Complete Privacy")
                                .font(.headline)

                            Text("Your passport data never leaves your device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.blue)
                            .font(.title)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Zero Knowledge")
                                .font(.headline)

                            Text("Prove facts without revealing personal information")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)

                // Connect Wallet Button
                Button(action: connectWallet) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Image(systemName: "link.circle.fill")
                        Text(isLoading ? "Connecting..." : "Connect Wallet")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .disabled(isLoading)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func connectWallet() {
        isLoading = true

        Task {
            do {
                _ = try await authManager.signInAsIndividual()

                await MainActor.run {
                    isLoading = false
                    // Navigation will happen automatically via authManager state change
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Step View Component

struct StepView: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)

                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        UserOnboardingView()
            .environmentObject(AuthenticationManager.shared)
    }
}
