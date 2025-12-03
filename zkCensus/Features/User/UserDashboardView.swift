import SwiftUI

struct UserDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0

    init() {
        // Customize TabBar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1.0)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home / Census Discovery
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // My Proofs
            MyProofsView()
                .tabItem {
                    Label("My Proofs", systemImage: "person.badge.key")
                }
                .tag(1)

            // Companies
            UserCompaniesView()
                .tabItem {
                    Label("Companies", systemImage: "building.2.fill")
                }
                .tag(2)

            // Profile
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.black)
    }
}

// MARK: - Home View

struct HomeView: View {
    @State private var censuses: [CensusMetadata] = []
    @State private var isLoading = false
    @State private var showScanPassport = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                BackgroundGradientView()

                ScrollView {
                    VStack(spacing: 24) {
                        // Quick Actions
                        quickActionsView

                        // Available Census
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Census")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal)

                            if censuses.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(censuses) { census in
                                    NavigationLink(destination: JoinCensusView(census: census)) {
                                        CensusCard(census: census)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("zk-Census")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                await loadCensuses()
            }
            .sheet(isPresented: $showScanPassport) {
                PassportScannerView()
            }
        }
    }

    private var quickActionsView: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "camera.fill",
                    title: "Scan Passport",
                    color: .black
                ) {
                    showScanPassport = true
                }

                QuickActionButton(
                    icon: "building.2.fill",
                    title: "Find Companies",
                    color: .black
                ) {
                    // Navigate to companies
                }
            }
        }
        .padding(.horizontal)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No active census available")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func loadCensuses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let all = try await APIClient.shared.listCensuses()
            censuses = all.filter { $0.active }
        } catch {
            print("Failed to load censuses: \(error)")
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Census Card

struct CensusCard: View {
    let census: CensusMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(census.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(census.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack {
                Label(census.memberCount, systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                if census.enableLocation {
                    Label("Location", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                Text("Min age: \(census.minAge)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - My Proofs View

struct MyProofsView: View {
    @State private var registrations: [Registration] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                BackgroundGradientView()

                ScrollView {
                    if registrations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "shield.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No Proofs Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("Scan your passport to create your first ZK proof")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(registrations) { registration in
                                ProofRow(registration: registration)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Proofs")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

struct ProofRow: View {
    let registration: Registration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Census ID: \(registration.censusId)")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                StatusBadge(isActive: registration.status == .verified)
            }

            HStack {
                if let ageRange = registration.ageRangeEnum {
                    Label(ageRange.displayName, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                if let continent = registration.continentEnum {
                    Label(continent.displayName, systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Text(registration.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - User Companies View

struct UserCompaniesView: View {
    @State private var companies: [CompanyPage] = []
    @State private var connections: [UserConnection] = []
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                BackgroundGradientView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Connections Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Connections")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            if connections.isEmpty {
                                Text("No connections yet")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.subheadline)
                                    .padding(.horizontal)
                            } else {
                                ForEach(connections) { connection in
                                    NavigationLink(destination: CompanyDetailView(connection: connection)) {
                                        UserConnectionRow(connection: connection)
                                    }
                                }
                            }
                        }

                        // Discover Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Discover Companies")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            ForEach(companies) { company in
                                NavigationLink(destination: CompanyPublicView(company: company)) {
                                    CompanyRow(company: company)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Companies")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.black)
                    }
                }
            }
            .task {
                await loadCompanies()
            }
        }
    }

    private func loadCompanies() async {
        do {
            companies = try await APIClient.shared.listCompanies()
            connections = try await APIClient.shared.getUserConnections()
        } catch {
            print("Failed to load companies: \(error)")
        }
    }
}

struct UserConnectionRow: View {
    let connection: UserConnection

    var body: some View {
        HStack {
            // Company logo or placeholder
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(connection.companyName.prefix(2).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(connection.companyName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(connection.proofCount) proof(s) shared")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct CompanyRow: View {
    let company: CompanyPage

    var body: some View {
        HStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.white.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(company.companyName)
                        .font(.headline)
                        .foregroundColor(.white)

                    if company.verificationStatus == .verified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }

                Text(company.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)

                if let members = company.totalMembers {
                    Text("\(members) members")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
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
        .padding(.horizontal)
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                BackgroundGradientView()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .shadow(color: .white.opacity(0.1), radius: 10)

                            VStack(spacing: 4) {
                                Text("Individual User")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                if let user = authManager.currentUser,
                                   let proofCount = user.zkProofCount {
                                    Text("\(proofCount) ZK proof(s) created")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.top, 20)

                        // Wallet Section
                        if let address = authManager.currentUser?.walletAddress {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Wallet")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal)

                                HStack {
                                    Text("Address")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(address.prefix(8) + "..." + address.suffix(8))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                        }

                        // Actions Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Actions")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal)

                            VStack(spacing: 1) {
                                NavigationLink(destination: PrivacySettingsView()) {
                                    HStack {
                                        Label("Privacy Settings", systemImage: "lock.shield")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                }

                                Button {
                                    PassportScannerService().clearAllPassportData()
                                } label: {
                                    HStack {
                                        Label("Clear Passport Cache", systemImage: "trash")
                                            .foregroundColor(.red.opacity(0.8))
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                }

                                Button(role: .destructive) {
                                    authManager.signOut()
                                } label: {
                                    HStack {
                                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                }
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Profile")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Placeholder Views

struct JoinCensusView: View {
    let census: CensusMetadata

    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.11, blue: 0.14).ignoresSafeArea()
            Text("Join Census: \(census.name)")
                .foregroundColor(.white)
        }
    }
}

struct CompanyDetailView: View {
    let connection: UserConnection

    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.11, blue: 0.14).ignoresSafeArea()
            Text("Company Detail: \(connection.companyName)")
                .foregroundColor(.white)
        }
    }
}

struct CompanyPublicView: View {
    let company: CompanyPage

    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.11, blue: 0.14).ignoresSafeArea()
            Text("Company: \(company.companyName)")
                .foregroundColor(.white)
        }
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        ZStack {
            BackgroundGradientView()
            Text("Privacy Settings")
                .foregroundColor(.white)
        }
    }
}

#Preview {
    UserDashboardView()
        .environmentObject(AuthenticationManager.shared)
}
