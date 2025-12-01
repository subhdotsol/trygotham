import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {

                    // MARK: Background – Full screen gradient or image
                    // If you have an "Onboarding" image in Assets.xcassets, it will be used
                    // Otherwise, a beautiful gradient will be shown
                    Group {
                        if let _ = UIImage(named: "Onboarding") {
                            Image("Onboarding")
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()
                                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                        } else {
                            // Fallback gradient background
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.1, green: 0.2, blue: 0.45),
                                    Color(red: 0.2, green: 0.3, blue: 0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .ignoresSafeArea()
                        }
                    }

                    // Subtle vignette / contrast overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.14),
                            Color.clear,
                            Color.black.opacity(0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // MARK: Foreground content
                    VStack {
                        Spacer(minLength: geometry.size.height * 0.12)

                        // Tagline
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Democracy doesn't need your name")
                                .font(.system(size: 34, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4)
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                            Text("Prove your identity with zero knowledge. Your passport stays private.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(2)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, geometry.size.height * 0.08)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        // MARK: Buttons
                        VStack(spacing: 14) {

                            // Continue with Google
                            Button(action: {
                                print("Continue with Google")
                                handleGoogleLogin()
                            }) {
                                HStack {
                                    Image("google_logo")
                                        .resizable()
                                        .renderingMode(.original)
                                        .frame(width: 22, height: 22)
                                        .cornerRadius(3)

                                    Text("Continue with Google")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                )
                                .shadow(color: Color.black.opacity(0.12),
                                        radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(PressableButtonStyle())

                            // Continue with Email
                            Button(action: {
                                print("Continue with email")
                                handleEmailLogin()
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 18, weight: .medium))

                                    Text("Continue with email")
                                        .font(.system(size: 17, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)

                        // MARK: Legal text
                        VStack(spacing: 6) {
                            Text("By pressing \"Continue\", you agree to our")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))

                            HStack(spacing: 6) {
                                Button(action: { print("Terms tapped") }) {
                                    Text("Terms of Service")
                                        .font(.system(size: 12, weight: .medium))
                                        .underline()
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                Text("and")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.65))
                                Button(action: { print("Privacy tapped") }) {
                                    Text("Privacy Policy")
                                        .font(.system(size: 12, weight: .medium))
                                        .underline()
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                        }
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))

                        // Privacy indicators
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 11))
                                Text("Encrypted")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.7))

                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 3, height: 3)

                            HStack(spacing: 4) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 11))
                                Text("No tracking")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 10) - 6)
                    }
                    .padding(.horizontal)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Login Methods

    private func handleGoogleLogin() {
        print("Continue with Google - BYPASSED for development")
        // TEMPORARY: Bypass Google authentication for development/testing
        // In production, this should properly authenticate with Privy
        
        /* COMMENTED OUT - Original Privy Google Authentication
        print("Continue with Google via Privy")
        Task {
            do {
                let user = try await PrivyService.shared.loginWithGoogle()
                print("Google login successful: \(user.id)")
                // Handle successful login - navigate to appropriate screen
            } catch {
                await MainActor.run {
                    errorMessage = "Google login failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
        */
        
        // Simulate successful authentication and navigate to user type selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Google authentication bypassed - user authenticated")
            // Mark user as authenticated to proceed to the app
            self.authManager.isAuthenticated = true
            // Set a default user type (can be changed based on actual flow)
            self.authManager.userType = .individual
        }
    }

    private func handleEmailLogin() {
        print("Continue with email - BYPASSED for development")
        // TEMPORARY: Bypass email authentication for development/testing
        // In production, this should properly authenticate with Privy

        // Simulate successful authentication and navigate to user type selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Email authentication bypassed - user authenticated")
            // Mark user as authenticated to proceed to the app
            self.authManager.isAuthenticated = true
            // Set a default user type (can be changed based on actual flow)
            self.authManager.userType = .individual
        }
    }
}

// MARK: - Email Login View (to be created)
// You can create this as a separate view for entering email and verification code

// MARK: Button press animation
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: Preview
#Preview {
    OnboardingView()
        .environmentObject(AuthenticationManager.shared)
}
