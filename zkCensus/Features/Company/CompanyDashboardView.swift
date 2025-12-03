import SwiftUI

struct CompanyDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var showCreateCensus = false
    
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
            // Census Management
            CensusListView()
                .tabItem {
                    Label("Census", systemImage: "list.bullet.clipboard")
                }
                .tag(0)

            // Members & Statistics
            CompanyStatsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(1)

            // Connections
            CompanyConnectionsView()
                .tabItem {
                    Label("Members", systemImage: "person.3.fill")
                }
                .tag(2)

            // Profile
            CompanyProfileView()
                .tabItem {
                    Label("Profile", systemImage: "building.2.fill")
                }
                .tag(3)
        }
        .accentColor(.black)
        .sheet(isPresented: $showCreateCensus) {
            CreateCensusView()
        }
    }
}

// MARK: - Census List View

struct CensusListView: View {
    @State private var censuses: [CensusMetadata] = []
    @State private var isLoading = false
    @State private var showCreateCensus = false

    var body: some View {
        NavigationStack {
            ZStack {
                if censuses.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    List(censuses) { census in
                        NavigationLink(destination: CensusDetailView(census: census)) {
                            CensusRow(census: census)
                        }
                    }
                }
            }
            .navigationTitle("My Census")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateCensus = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateCensus) {
                CreateCensusView()
            }
            .task {
                await loadCensuses()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Census Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first census to start verifying members")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showCreateCensus = true }) {
                Label("Create Census", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    private func loadCensuses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            censuses = try await APIClient.shared.listCensuses()
        } catch {
            print("Failed to load censuses: \(error)")
        }
    }
}

// MARK: - Census Row

struct CensusRow: View {
    let census: CensusMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(census.name)
                    .font(.headline)

                Spacer()

                StatusBadge(isActive: census.active)
            }

            Text(census.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Label(census.memberCount, systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(census.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let isActive: Bool

    var body: some View {
        Text(isActive ? "Active" : "Closed")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(isActive ? .green : .gray)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isActive ? Color.green : Color.gray).opacity(0.2))
            .cornerRadius(6)
    }
}

// MARK: - Company Stats View

struct CompanyStatsView: View {
    @State private var stats: CensusStatistics?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let stats = stats {
                        // Total Members Card
                        StatCard(
                            title: "Total Members",
                            value: "\(stats.totalMembers)",
                            icon: "person.3.fill",
                            color: .blue
                        )

                        // Age Distribution
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Age Distribution")
                                .font(.headline)

                            ForEach(stats.ageData, id: \.range) { item in
                                DistributionBar(
                                    label: item.range.displayName,
                                    value: item.count,
                                    total: stats.totalMembers,
                                    color: .blue
                                )
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)

                        // Location Distribution
                        if !stats.continentData.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Location Distribution")
                                    .font(.headline)

                                ForEach(stats.continentData, id: \.continent) { item in
                                    DistributionBar(
                                        label: item.continent.displayName,
                                        value: item.count,
                                        total: stats.totalMembers,
                                        color: .green
                                    )
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                    } else if isLoading {
                        ProgressView("Loading statistics...")
                    } else {
                        Text("No statistics available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .task {
                await loadStats()
            }
        }
    }

    private func loadStats() async {
        isLoading = true
        defer { isLoading = false }

        do {
            stats = try await APIClient.shared.getGlobalStats()
        } catch {
            print("Failed to load stats: \(error)")
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(color.opacity(0.3))
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Distribution Bar

struct DistributionBar: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color

    private var percentage: Double {
        total > 0 ? Double(value) / Double(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(value)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("(\(Int(percentage * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}

// MARK: - Company Connections View

struct CompanyConnectionsView: View {
    @State private var connections: [UserConnection] = []

    var body: some View {
        NavigationStack {
            List(connections) { connection in
                ConnectionRow(connection: connection)
            }
            .navigationTitle("Connected Members")
        }
    }
}

struct ConnectionRow: View {
    let connection: UserConnection

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(connection.companyName.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Member")
                    .font(.headline)

                Text("\(connection.proofCount) proof(s) shared")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(connection.connectedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Company Profile View

struct CompanyProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let user = authManager.currentUser {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading) {
                                    Text(user.companyName ?? "Company")
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    if let status = user.verificationStatus {
                                        HStack {
                                            Circle()
                                                .fill(Color(status.color))
                                                .frame(width: 8, height: 8)
                                            Text(status.displayName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }

                            if let description = user.companyDescription {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if let website = user.companyWebsite {
                                Link(destination: URL(string: website)!) {
                                    Label(website, systemImage: "link")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
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

#Preview {
    CompanyDashboardView()
        .environmentObject(AuthenticationManager.shared)
}
