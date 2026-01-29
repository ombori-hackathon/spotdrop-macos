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
    case restaurant
    case bar
    case park
    case museum
    case shop
    case other

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .cafe: return "#22C55E"
        case .restaurant: return "#F97316"
        case .bar: return "#A855F7"
        case .park: return "#14B8A6"
        case .museum: return "#3B82F6"
        case .shop: return "#EC4899"
        case .other: return "#6B7280"
        }
    }
}
