import Foundation

// MARK: - Census Metadata
struct CensusMetadata: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let creator: String // Solana public key
    let createdAt: Date
    let active: Bool
    let enableLocation: Bool
    let minAge: Int
    let merkleRoot: String
    let ipfsHash: String?
    let totalMembers: Int?
    let ageDistribution: [Int]?
    let continentDistribution: [Int]?
    let lastUpdated: Date?

    var isActive: Bool {
        return active
    }

    var memberCount: String {
        if let total = totalMembers {
            return "\(total) member\(total == 1 ? "" : "s")"
        }
        return "0 members"
    }
}

// MARK: - Create Census Request
struct CreateCensusRequest: Codable {
    let name: String
    let description: String
    let enableLocation: Bool
    let minAge: Int
    let creatorPublicKey: String
    let signature: String
}

// MARK: - Census Statistics
struct CensusStatistics: Codable {
    let censusId: String
    let totalMembers: Int
    let ageDistribution: [String: Int]
    let continentDistribution: [String: Int]?
    let lastUpdated: Date

    var ageData: [(range: AgeRange, count: Int)] {
        ageDistribution.compactMap { key, value in
            guard let range = Int(key), let ageRange = AgeRange(rawValue: range) else {
                return nil
            }
            return (ageRange, value)
        }.sorted { $0.range.rawValue < $1.range.rawValue }
    }

    var continentData: [(continent: Continent, count: Int)] {
        continentDistribution?.compactMap { key, value in
            guard let cont = Int(key), let continent = Continent(rawValue: cont) else {
                return nil
            }
            return (continent, value)
        }.sorted { $0.continent.rawValue < $1.continent.rawValue } ?? []
    }
}

// MARK: - Company Page
struct CompanyPage: Codable, Identifiable {
    let id: String
    let companyName: String
    let description: String
    let logoUrl: String?
    let website: String?
    let industry: String?
    let size: CompanySize?
    let foundedYear: Int?
    let walletAddress: String
    let verificationStatus: VerificationStatus
    let createdAt: Date
    let updatedAt: Date

    // Census information
    var censuses: [CensusMetadata]?
    var totalMembers: Int?
    var verifiedShares: Int?

    enum CompanySize: String, Codable {
        case startup = "startup"           // 1-10
        case small = "small"               // 11-50
        case medium = "medium"             // 51-200
        case large = "large"               // 201-1000
        case enterprise = "enterprise"     // 1000+

        var displayName: String {
            switch self {
            case .startup: return "Startup (1-10)"
            case .small: return "Small (11-50)"
            case .medium: return "Medium (51-200)"
            case .large: return "Large (201-1000)"
            case .enterprise: return "Enterprise (1000+)"
            }
        }
    }
}

// MARK: - Create Company Page Request
struct CreateCompanyPageRequest: Codable {
    let companyName: String
    let description: String
    let logoUrl: String?
    let website: String?
    let industry: String?
    let size: String?
    let foundedYear: Int?
    let walletAddress: String
    let signature: String
}

// MARK: - Connection Request
struct ConnectionRequest: Codable, Identifiable {
    let id: String
    let userId: String
    let companyId: String
    let message: String?
    let status: ConnectionStatus
    let createdAt: Date
    let respondedAt: Date?

    enum ConnectionStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case rejected = "rejected"

        var displayName: String {
            rawValue.capitalized
        }
    }
}

// MARK: - User Connection (established connection between user and company)
struct UserConnection: Codable, Identifiable {
    let id: String
    let userId: String
    let companyId: String
    let companyName: String
    let companyLogoUrl: String?
    let connectedAt: Date
    let sharedProofs: [ZKShare]?
    let lastInteraction: Date?

    var proofCount: Int {
        sharedProofs?.count ?? 0
    }
}
