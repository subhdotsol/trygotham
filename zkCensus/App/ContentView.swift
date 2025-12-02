import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
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
            
            // Logo - Try custom image first, fallback to SF Symbol
            Group {
                if let _ = UIImage(named: "ghost") {
                    Image("ghost")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                } else {
                    // Fallback to SF Symbol
                    Image(systemName: "person.fill.questionmark")
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
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(SolanaService.shared)
}
