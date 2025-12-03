import SwiftUI

struct CompanyOnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var companyName = ""
    @State private var description = ""
    @State private var website = ""
    @State private var industry = ""
    @State private var selectedSize: CompanyPage.CompanySize?

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background gradient
            BackgroundGradientView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Company Profile")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        Text("Set up your company page to start creating census")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.8))
                    }
                    .padding(.top)

                    // Form Fields
                    VStack(alignment: .leading, spacing: 20) {
                        // Company Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Company Name")
                                .font(.headline)
                                .foregroundColor(.black)
                            TextField("", text: $companyName)
                                .placeholder(when: companyName.isEmpty) {
                                    Text("Enter company name").foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(8)
                                .foregroundColor(.black)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.black)
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .padding(4)
                                .scrollContentBackground(.hidden) // Hide default background
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(8)
                                .foregroundColor(.black)
                        }

                        // Website
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Website (Optional)")
                                .font(.headline)
                                .foregroundColor(.black)
                            TextField("", text: $website)
                                .placeholder(when: website.isEmpty) {
                                    Text("https://example.com").foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(8)
                                .foregroundColor(.black)
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }

                        // Industry
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Industry (Optional)")
                                .font(.headline)
                                .foregroundColor(.black)
                            TextField("", text: $industry)
                                .placeholder(when: industry.isEmpty) {
                                    Text("e.g., Technology, Healthcare").foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(8)
                                .foregroundColor(.black)
                        }

                        // Company Size
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Company Size (Optional)")
                                .font(.headline)
                                .foregroundColor(.black)

                            VStack(spacing: 8) {
                                ForEach([
                                    CompanyPage.CompanySize.startup,
                                    .small,
                                    .medium,
                                    .large,
                                    .enterprise
                                ], id: \.self) { size in
                                    Button {
                                        selectedSize = size
                                    } label: {
                                        HStack {
                                            Text(size.displayName)
                                                .foregroundColor(.black)
                                            Spacer()
                                            if selectedSize == size {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .padding()
                                        .background(selectedSize == size ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedSize == size ? Color.black : Color.clear, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Connect Wallet & Create Button
                    Button(action: createCompanyProfile) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            }
                            Text(isLoading ? "Creating Profile..." : "Connect Wallet & Create Profile")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.white : Color.gray)
                        .cornerRadius(12)
                        .shadow(color: isFormValid ? .white.opacity(0.2) : .clear, radius: 10, x: 0, y: 0)
                    }
                    .disabled(!isFormValid || isLoading)

                    // Info Box
                    InfoBox(
                        icon: "info.circle.fill",
                        title: "Verification Process",
                        message: "Your company will be verified before you can create census. This usually takes 1-2 business days."
                    )
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !companyName.isEmpty && description.count >= 10
    }

    private func createCompanyProfile() {
        isLoading = true

        Task {
            do {
                // First, sign in to connect wallet
                _ = try await authManager.signInAsCompany()

                // Complete onboarding
                try await authManager.completeCompanyOnboarding(
                    companyName: companyName,
                    description: description,
                    website: website.isEmpty ? nil : website,
                    industry: industry.isEmpty ? nil : industry,
                    size: selectedSize
                )

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

// MARK: - Info Box Component

struct InfoBox: View {
    let icon: String
    let title: String
    let message: String
    var color: Color = .black

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.8))
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
    }
}

// Helper for placeholder in custom TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    NavigationStack {
        CompanyOnboardingView()
            .environmentObject(AuthenticationManager.shared)
    }
}
