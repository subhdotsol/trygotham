import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.scenePhase) var scenePhase
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashScreen(isActive: $showSplash)
            } else if authManager.isAuthenticated {
                // Show appropriate dashboard based on user type
                if authManager.userType == .company {
                    CompanyDashboardView()
                } else {
                    UserDashboardView()
                }
            } else {
                // Show onboarding
                OnboardingView()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !showSplash {
                // Reset splash screen when app becomes active from background
                showSplash = true
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var opacity: Double = 0
    @Binding var isActive: Bool
    
    var body: some View {
        ZStack {
            // Background gradient (Gotham Night)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.09, green: 0.11, blue: 0.14),
                    Color(red: 0.02, green: 0.02, blue: 0.03)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Logo - Load from bundle
            Group {
                if let ghostImage = loadGhostImage() {
                    Image(uiImage: ghostImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                } else {
                    // Fallback: Use a ghost-like SF Symbol
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
            }
            .opacity(opacity)
            .scaleEffect(isAnimating ? 1.0 : 0.85)
        }
        .onAppear {
            // Quick fade in
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
                isAnimating = true
            }
            
            // Show for 1 second total, then dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    opacity = 0.0
                }
                
                // Dismiss after fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isActive = false
                }
            }
        }
    }
    
    private func loadGhostImage() -> UIImage? {
        // Try multiple paths
        if let image = UIImage(named: "ghost") {
            return image
        }
        
        // Try loading from bundle
        if let path = Bundle.main.path(forResource: "ghost", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        // Try Assets catalog
        if let image = UIImage(named: "ghost", in: Bundle.main, compatibleWith: nil) {
            return image
        }
        
        return nil
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(SolanaService.shared)
}
