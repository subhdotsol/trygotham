import Foundation
import SwiftUI
import Combine

/// Manages user authentication and session state
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserProfile?
    @Published var userType: UserType?

    private let solanaService = SolanaService.shared
    private let apiClient = APIClient.shared
    private let persistence = PersistenceController.shared

    private init() {
        // Try to restore session
        restoreSession()
    }

    // MARK: - Authentication

    func signInAsCompany() async throws -> UserProfile {
        // Connect wallet
        let walletAddress = try await solanaService.connectWallet()

        // Check if company profile exists
        if let existingProfile = try? await fetchUserProfile(walletAddress: walletAddress),
           existingProfile.userType == .company {
            await updateAuthState(profile: existingProfile)
            return existingProfile
        }

        // Create new company profile (will be completed in onboarding)
        let profile = UserProfile(
            id: UUID().uuidString,
            userType: .company,
            walletAddress: walletAddress,
            createdAt: Date(),
            verificationStatus: .pending
        )

        await updateAuthState(profile: profile)

        return profile
    }

    func signInAsIndividual() async throws -> UserProfile {
        // Connect wallet
        let walletAddress = try await solanaService.connectWallet()

        // Check if user profile exists
        if let existingProfile = try? await fetchUserProfile(walletAddress: walletAddress),
           existingProfile.userType == .individual {
            await updateAuthState(profile: existingProfile)
            return existingProfile
        }

        // Create new user profile
        let profile = UserProfile(
            id: UUID().uuidString,
            userType: .individual,
            walletAddress: walletAddress,
            createdAt: Date(),
            hasCompletedKYC: false,
            zkProofCount: 0,
            connectedCompanies: []
        )

        await updateAuthState(profile: profile)

        return profile
    }

    func signOut() {
        // Disconnect wallet
        solanaService.disconnectWallet()

        // Clear session
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
            self.userType = nil
        }

        // Clear keychain
        KeychainManager.shared.clearUserData()

        // Clear local storage
        clearLocalProfile()
    }

    // MARK: - Profile Management

    func updateProfile(_ profile: UserProfile) async throws {
        // Save to backend (extended API - would need to implement)
        // For now, save locally
        saveLocalProfile(profile)

        await MainActor.run {
            self.currentUser = profile
        }
    }

    func completeCompanyOnboarding(
        companyName: String,
        description: String,
        website: String?,
        industry: String?,
        size: CompanyPage.CompanySize?
    ) async throws {
        guard var profile = currentUser,
              profile.userType == .company,
              let walletAddress = solanaService.walletAddress else {
            throw AuthError.notAuthenticated
        }

        // Sign message for verification
        let message = "Create company profile: \(companyName)"
        let signature = try await solanaService.signMessage(message)

        // Create company page
        let request = CreateCompanyPageRequest(
            companyName: companyName,
            description: description,
            logoUrl: profile.companyLogoUrl,
            website: website,
            industry: industry,
            size: size?.rawValue,
            foundedYear: nil,
            walletAddress: walletAddress,
            signature: signature
        )

        let companyPage = try await apiClient.createCompanyPage(request)

        // Update profile
        profile.companyName = companyName
        profile.companyDescription = description
        profile.companyWebsite = website
        profile.verificationStatus = companyPage.verificationStatus

        try await updateProfile(profile)
    }

    // MARK: - Session Management

    private func restoreSession() {
        // Restore wallet connection
        solanaService.restoreWalletConnection()

        // Restore profile from local storage
        if let profile = loadLocalProfile() {
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.currentUser = profile
                self.userType = profile.userType
            }
        }
    }

    private func updateAuthState(profile: UserProfile) async {
        saveLocalProfile(profile)

        await MainActor.run {
            self.isAuthenticated = true
            self.currentUser = profile
            self.userType = profile.userType
        }
    }

    private func fetchUserProfile(walletAddress: String) async throws -> UserProfile {
        // This would fetch from backend in production
        // For now, check local storage
        if let profile = loadLocalProfile(),
           profile.walletAddress == walletAddress {
            return profile
        }

        throw AuthError.profileNotFound
    }

    // MARK: - Local Storage

    private func saveLocalProfile(_ profile: UserProfile) {
        let context = persistence.container.viewContext

        // Fetch or create entity
        let fetchRequest = UserProfileEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", profile.id)

        let entity: UserProfileEntity
        if let existing = try? context.fetch(fetchRequest).first {
            entity = existing
        } else {
            entity = UserProfileEntity(context: context)
            entity.id = profile.id
            entity.createdAt = profile.createdAt
        }

        // Update fields
        entity.userType = profile.userType.rawValue
        entity.walletAddress = profile.walletAddress
        entity.companyName = profile.companyName
        entity.companyDescription = profile.companyDescription
        entity.companyLogoUrl = profile.companyLogoUrl
        entity.companyWebsite = profile.companyWebsite
        entity.verificationStatus = profile.verificationStatus?.rawValue
        entity.hasCompletedKYC = profile.hasCompletedKYC ?? false
        entity.zkProofCount = Int32(profile.zkProofCount ?? 0)
        entity.updatedAt = Date()

        persistence.save()

        // Save to keychain
        KeychainManager.shared.saveUserId(profile.id)
    }

    private func loadLocalProfile() -> UserProfile? {
        guard let userId = KeychainManager.shared.getUserId() else {
            return nil
        }

        let context = persistence.container.viewContext
        let fetchRequest = UserProfileEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userId)

        guard let entity = try? context.fetch(fetchRequest).first else {
            return nil
        }

        return UserProfile(
            id: entity.id ?? "",
            userType: UserType(rawValue: entity.userType ?? "") ?? .individual,
            walletAddress: entity.walletAddress ?? "",
            createdAt: entity.createdAt ?? Date(),
            companyName: entity.companyName,
            companyDescription: entity.companyDescription,
            companyLogoUrl: entity.companyLogoUrl,
            companyWebsite: entity.companyWebsite,
            verificationStatus: entity.verificationStatus.flatMap { VerificationStatus(rawValue: $0) },
            hasCompletedKYC: entity.hasCompletedKYC,
            zkProofCount: Int(entity.zkProofCount),
            connectedCompanies: nil
        )
    }

    private func clearLocalProfile() {
        guard let userId = KeychainManager.shared.getUserId() else {
            return
        }

        let context = persistence.container.viewContext
        let fetchRequest = UserProfileEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userId)

        if let entity = try? context.fetch(fetchRequest).first {
            context.delete(entity)
            persistence.save()
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case walletConnectionFailed
    case invalidUserType
    case onboardingIncomplete

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .profileNotFound:
            return "User profile not found."
        case .walletConnectionFailed:
            return "Failed to connect wallet."
        case .invalidUserType:
            return "Invalid user type."
        case .onboardingIncomplete:
            return "Please complete onboarding first."
        }
    }
}
