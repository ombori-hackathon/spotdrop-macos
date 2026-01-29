import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        self.isAuthenticated = KeychainManager.shared.hasTokens
    }

    func checkAuth() async {
        guard KeychainManager.shared.hasTokens else {
            isAuthenticated = false
            return
        }

        do {
            user = try await apiClient.getMe()
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            KeychainManager.shared.clearTokens()
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        error = nil

        do {
            _ = try await apiClient.login(email: email, password: password)
            user = try await apiClient.getMe()
            isAuthenticated = true
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func register(email: String, password: String, username: String) async {
        isLoading = true
        error = nil

        do {
            _ = try await apiClient.register(email: email, password: password, username: username)
            _ = try await apiClient.login(email: email, password: password)
            user = try await apiClient.getMe()
            isAuthenticated = true
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        KeychainManager.shared.clearTokens()
        user = nil
        isAuthenticated = false
    }
}
