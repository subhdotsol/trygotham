import Foundation
import PrivySDK
import Combine

/// Service for integrating with Privy for social login and embedded wallets
/// Official iOS SDK: https://github.com/privy-io/privy-ios
///
/// NOTE: Currently BYPASSED in OnboardingView.swift for development
/// The authentication methods below are functional but not being called.
/// See OnboardingView.swift handleGoogleLogin() and handleEmailLogin() for bypass logic.
@MainActor
class PrivyService: ObservableObject {
    static let shared = PrivyService()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: (any PrivyUser)?
    @Published var embeddedWalletAddress: String?

    private var privy: (any Privy)?
    private let privyAppId: String
    private let privyAppClientId: String

    private var authStateTask: Task<Void, Never>?

    private init() {
        // Get Privy App ID and Client ID from environment or config
        self.privyAppId = ProcessInfo.processInfo.environment["PRIVY_APP_ID"] ?? ""
        self.privyAppClientId = ProcessInfo.processInfo.environment["PRIVY_APP_CLIENT_ID"] ?? ""

        // Initialize Privy SDK
        if !privyAppId.isEmpty && !privyAppClientId.isEmpty {
            initializePrivy()
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Setup

    private func initializePrivy() {
        let config = PrivyConfig(appId: privyAppId, appClientId: privyAppClientId)
        self.privy = PrivySdk.initialize(config: config)

        // Start observing auth state changes
        observeAuthState()
    }

    private func observeAuthState() {
        guard let privy = privy else { return }

        authStateTask = Task {
            for await authState in privy.authStateStream {
                await handleAuthStateChange(authState)
            }
        }
    }

    private func handleAuthStateChange(_ authState: AuthState) async {
        switch authState {
        case .authenticated(let user):
            self.isAuthenticated = true
            self.currentUser = user

            // Get embedded wallet address if available
            if let solanaWallet = user.embeddedSolanaWallets.first {
                self.embeddedWalletAddress = solanaWallet.address
            }

        case .unauthenticated, .notReady, .authenticatedUnverified:
            self.isAuthenticated = false
            self.currentUser = nil
            self.embeddedWalletAddress = nil

        @unknown default:
            self.isAuthenticated = false
            self.currentUser = nil
            self.embeddedWalletAddress = nil
        }
    }

    // MARK: - Google OAuth Login

    /// Initiates Google OAuth login flow
    func loginWithGoogle() async throws -> any PrivyUser {
        guard let privy = privy else {
            throw PrivyError.notInitialized
        }

        do {
            let user = try await privy.oAuth.login(with: .google)
            return user
        } catch {
            throw PrivyError.authenticationFailed(error.localizedDescription)
        }
    }

    // MARK: - Email Login

    /// Sends login code to email
    func sendEmailCode(to email: String) async throws {
        guard let privy = privy else {
            throw PrivyError.notInitialized
        }

        do {
            try await privy.email.sendCode(to: email)
        } catch {
            throw PrivyError.authenticationFailed(error.localizedDescription)
        }
    }

    /// Login with email code
    func loginWithEmailCode(_ code: String, sentTo email: String) async throws -> any PrivyUser {
        guard let privy = privy else {
            throw PrivyError.notInitialized
        }

        do {
            let user = try await privy.email.loginWithCode(code, sentTo: email)
            return user
        } catch {
            throw PrivyError.authenticationFailed(error.localizedDescription)
        }
    }

    // MARK: - Embedded Wallet

    /// Creates or retrieves the user's embedded Solana wallet
    func getOrCreateSolanaWallet() async throws -> any EmbeddedSolanaWallet {
        guard let user = currentUser else {
            throw PrivyError.notAuthenticated
        }

        // Check if wallet already exists
        if let existingWallet = user.embeddedSolanaWallets.first {
            return existingWallet
        }

        // Create new wallet
        do {
            let wallet = try await user.createSolanaWallet()
            await MainActor.run {
                self.embeddedWalletAddress = wallet.address
            }
            return wallet
        } catch {
            throw PrivyError.walletCreationFailed(error.localizedDescription)
        }
    }

    /// Signs a message with the embedded Solana wallet
    func signMessage(_ message: String) async throws -> String {
        guard let wallet = currentUser?.embeddedSolanaWallets.first else {
            throw PrivyError.walletNotFound
        }

        do {
            let signature = try await wallet.provider.signMessage(message: message)
            return signature
        } catch {
            throw PrivyError.signingFailed(error.localizedDescription)
        }
    }

    // MARK: - Logout

    func logout() async {
        guard let user = currentUser else { return }

        await user.logout()

        self.isAuthenticated = false
        self.currentUser = nil
        self.embeddedWalletAddress = nil
    }

    // MARK: - Access Token

    func getAccessToken() async throws -> String {
        guard let user = currentUser else {
            throw PrivyError.notAuthenticated
        }

        return try await user.getAccessToken()
    }
}

// MARK: - Errors

enum PrivyError: LocalizedError {
    case notInitialized
    case authenticationFailed(String)
    case walletCreationFailed(String)
    case walletNotFound
    case signingFailed(String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Privy SDK not initialized. Please set PRIVY_APP_ID."
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .walletCreationFailed(let message):
            return "Failed to create wallet: \(message)"
        case .walletNotFound:
            return "Embedded wallet not found"
        case .signingFailed(let message):
            return "Failed to sign: \(message)"
        case .notAuthenticated:
            return "Not authenticated with Privy"
        }
    }
}
