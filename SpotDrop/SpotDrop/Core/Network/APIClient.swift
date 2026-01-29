import Foundation
import Combine

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .unauthorized: return "Unauthorized"
        case .serverError(let code): return "Server error: \(code)"
        case .decodingError: return "Failed to decode response"
        case .networkError(let error): return error.localizedDescription
        }
    }
}

@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = "http://localhost:8000/api"
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        authenticated: Bool = false
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated {
            if let token = KeychainManager.shared.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    private func requestNoContent(
        endpoint: String,
        method: String,
        authenticated: Bool = true
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if authenticated {
            if let token = KeychainManager.shared.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode >= 400 {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Auth

    func register(email: String, password: String, username: String) async throws -> User {
        struct RegisterRequest: Encodable {
            let email: String
            let password: String
            let username: String
        }

        return try await request(
            endpoint: "/auth/register",
            method: "POST",
            body: RegisterRequest(email: email, password: password, username: username)
        )
    }

    func login(email: String, password: String) async throws -> TokenResponse {
        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }

        let response: TokenResponse = try await request(
            endpoint: "/auth/login",
            method: "POST",
            body: LoginRequest(email: email, password: password)
        )

        KeychainManager.shared.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        return response
    }

    func getMe() async throws -> User {
        return try await request(endpoint: "/users/me", authenticated: true)
    }

    // MARK: - Spots

    func getSpots(category: String? = nil, minRating: Double? = nil) async throws -> SpotsResponse {
        var endpoint = "/spots?size=100"
        if let category = category {
            endpoint += "&category=\(category)"
        }
        if let minRating = minRating {
            endpoint += "&min_rating=\(minRating)"
        }
        return try await request(endpoint: endpoint)
    }

    func getSpot(id: Int) async throws -> Spot {
        return try await request(endpoint: "/spots/\(id)")
    }

    func createSpot(_ spot: CreateSpotRequest) async throws -> Spot {
        return try await request(endpoint: "/spots", method: "POST", body: spot, authenticated: true)
    }

    func deleteSpot(id: Int) async throws {
        try await requestNoContent(endpoint: "/spots/\(id)", method: "DELETE")
    }

    func uploadImage(spotId: Int, imageData: Data, isPrimary: Bool = false) async throws -> SpotImage {
        guard let url = URL(string: "\(baseURL)/spots/\(spotId)/images?is_primary=\(isPrimary)") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = KeychainManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }

        return try decoder.decode(SpotImage.self, from: data)
    }
}
