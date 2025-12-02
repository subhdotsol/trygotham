import SwiftUI

struct UserOnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background gradient (Gotham Night)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.09, green: 0.11, blue: 0.14), // Dark slate
                    Color(red: 0.02, green: 0.02, blue: 0.03)  // Almost black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 0)

                        Text("Get Started")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Connect your Solana wallet to start creating zero-knowledge proofs")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    // How it Works
                    VStack(alignment: .leading, spacing: 20) {
                        Text("How it works")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

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
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Privacy Guarantee
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.white)
                                .font(.title)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Complete Privacy")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("Your passport data never leaves your device")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                        HStack {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(.white)
                                .font(.title)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Zero Knowledge")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("Prove facts without revealing personal information")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)

                    // Connect Wallet Button
                    Button(action: connectWallet) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            }
                            Image(systemName: "link.circle.fill")
                            Text(isLoading ? "Connecting..." : "Connect Wallet")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 0)
                        .padding(.horizontal)
                    }
                    .disabled(isLoading)
                }
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
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)

                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
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
