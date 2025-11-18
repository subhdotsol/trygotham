import SwiftUI

struct UserDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0

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
                    Label("My Proofs", systemImage: "shield.checkmark.fill")
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
    }
}

// MARK: - Home View

struct HomeView: View {
    @State private var censuses: [CensusMetadata] = []
    @State private var isLoading = false
    @State private var showScanPassport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Actions
                    quickActionsView

                    // Available Census
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Census")
                            .font(.title2)
                            .fontWeight(.bold)
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
            .navigationTitle("zk-Census")
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
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "camera.fill",
                    title: "Scan Passport",
                    color: .blue
                ) {
                    showScanPassport = true
                }

                QuickActionButton(
                    icon: "building.2.fill",
                    title: "Find Companies",
                    color: .green
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
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
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
                        .foregroundColor(.primary)

                    Text(census.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            HStack {
                Label(census.memberCount, systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if census.enableLocation {
                    Label("Location", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Text("Min age: \(census.minAge)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - My Proofs View

struct MyProofsView: View {
    @State private var registrations: [Registration] = []

    var body: some View {
        NavigationStack {
            List {
                if registrations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shield.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Proofs Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Scan your passport to create your first ZK proof")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(registrations) { registration in
                        ProofRow(registration: registration)
                    }
                }
            }
            .navigationTitle("My Proofs")
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

                Spacer()

                StatusBadge(isActive: registration.status == .verified)
            }

            HStack {
                if let ageRange = registration.ageRangeEnum {
                    Label(ageRange.displayName, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let continent = registration.continentEnum {
                    Label(continent.displayName, systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(registration.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Companies View

struct UserCompaniesView: View {
    @State private var companies: [CompanyPage] = []
    @State private var connections: [UserConnection] = []
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            List {
                Section("My Connections") {
                    if connections.isEmpty {
                        Text("No connections yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(connections) { connection in
                            NavigationLink(destination: CompanyDetailView(connection: connection)) {
                                UserConnectionRow(connection: connection)
                            }
                        }
                    }
                }

                Section("Discover Companies") {
                    ForEach(companies) { company in
                        NavigationLink(destination: CompanyPublicView(company: company)) {
                            CompanyRow(company: company)
                        }
                    }
                }
            }
            .navigationTitle("Companies")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
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
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(connection.companyName.prefix(2).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(connection.companyName)
                    .font(.headline)

                Text("\(connection.proofCount) proof(s) shared")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

struct CompanyRow: View {
    let company: CompanyPage

    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(company.companyName)
                        .font(.headline)

                    if company.verificationStatus == .verified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }

                Text(company.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if let members = company.totalMembers {
                    Text("\(members) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Individual User")
                                .font(.title3)
                                .fontWeight(.semibold)

                            if let user = authManager.currentUser,
                               let proofCount = user.zkProofCount {
                                Text("\(proofCount) ZK proof(s) created")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Wallet") {
                    if let address = authManager.currentUser?.walletAddress {
                        HStack {
                            Text("Address")
                            Spacer()
                            Text(address.prefix(8) + "..." + address.suffix(8))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Privacy") {
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy Settings", systemImage: "lock.shield")
                    }

                    Button {
                        // Clear passport data
                        PassportScannerService().clearAllPassportData()
                    } label: {
                        Label("Clear Passport Cache", systemImage: "trash")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Placeholder Views

struct JoinCensusView: View {
    let census: CensusMetadata

    var body: some View {
        Text("Join Census: \(census.name)")
    }
}

struct CompanyDetailView: View {
    let connection: UserConnection

    var body: some View {
        Text("Company Detail: \(connection.companyName)")
    }
}

struct CompanyPublicView: View {
    let company: CompanyPage

    var body: some View {
        Text("Company: \(company.companyName)")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
    }
}

#Preview {
    UserDashboardView()
        .environmentObject(AuthenticationManager.shared)
}
