import Foundation
import Combine

@MainActor
class SpotsViewModel: ObservableObject {
    @Published var spots: [Spot] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchSpots() async {
        isLoading = true
        error = nil

        do {
            let response = try await apiClient.getSpots()
            spots = response.items
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func deleteSpot(_ spot: Spot) async {
        do {
            try await apiClient.deleteSpot(id: spot.id)
            spots.removeAll { $0.id == spot.id }
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
