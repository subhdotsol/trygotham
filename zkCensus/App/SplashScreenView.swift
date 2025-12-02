import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var opacity: Double = 0
    @Binding var isActive: Bool
    
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
            
            // Logo
            Image("ghost")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
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
                    isActive = true
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isActive: .constant(false))
}
