import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let username: String
    let avatarUrl: String?
    let isActive: Bool
    let createdAt: Date
}

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
}

struct SpotImage: Codable, Identifiable {
    let id: Int
    let url: String
    let isPrimary: Bool
    let spotId: Int
    let createdAt: Date
}

struct Spot: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let category: String
    let rating: Double?
    let latitude: Double
    let longitude: Double
    let address: String?
    let best: String?
    let bestTime: String?
    let priceLevel: Int?
    let userId: Int
    let user: User
    let images: [SpotImage]
    let createdAt: Date
    let updatedAt: Date?
}

struct SpotsResponse: Codable {
    let items: [Spot]
    let total: Int
    let page: Int
    let size: Int
    let pages: Int
}

struct CreateSpotRequest: Codable {
    let title: String
    let description: String?
    let category: String
    let rating: Double?
    let latitude: Double
    let longitude: Double
    let address: String?
    let best: String?
    let bestTime: String?
    let priceLevel: Int?
}

enum SpotCategory: String, CaseIterable, Identifiable {
    case cafe
    case viewpoint
    case activity
    case shop
    case bar
    case restaurant

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .cafe: return "#F59E0B"       // amber
        case .viewpoint: return "#22C55E"  // green
        case .activity: return "#3B82F6"   // blue
        case .shop: return "#EC4899"       // pink
        case .bar: return "#A855F7"        // purple
        case .restaurant: return "#EF4444" // red
        }
    }
}
