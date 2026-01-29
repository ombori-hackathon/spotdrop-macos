import Foundation
import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
class AddSpotViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var category: SpotCategory = .cafe
    @Published var rating: Double = 0
    @Published var latitude = ""
    @Published var longitude = ""
    @Published var address = ""
    @Published var best = ""
    @Published var bestTime = ""
    @Published var priceLevel: Int = 0
    @Published var selectedImages: [NSImage] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    var isValid: Bool {
        !title.isEmpty &&
        !latitude.isEmpty &&
        !longitude.isEmpty &&
        Double(latitude) != nil &&
        Double(longitude) != nil
    }

    func addImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK {
            for url in panel.urls {
                if let image = NSImage(contentsOf: url), selectedImages.count < 5 {
                    selectedImages.append(image)
                }
            }
        }
    }

    func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }

    func createSpot() async -> Spot? {
        guard isValid else {
            error = "Please fill in all required fields"
            return nil
        }

        isLoading = true
        error = nil

        do {
            let request = CreateSpotRequest(
                title: title,
                description: description.isEmpty ? nil : description,
                category: category.rawValue,
                rating: rating > 0 ? rating : nil,
                latitude: Double(latitude)!,
                longitude: Double(longitude)!,
                address: address.isEmpty ? nil : address,
                best: best.isEmpty ? nil : best,
                bestTime: bestTime.isEmpty ? nil : bestTime,
                priceLevel: priceLevel > 0 ? priceLevel : nil
            )

            let spot = try await apiClient.createSpot(request)

            for (index, image) in selectedImages.enumerated() {
                if let imageData = image.jpegData() {
                    _ = try await apiClient.uploadImage(
                        spotId: spot.id,
                        imageData: imageData,
                        isPrimary: index == 0
                    )
                }
            }

            isLoading = false
            return spot
        } catch let apiError as APIError {
            error = apiError.errorDescription
            isLoading = false
            return nil
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return nil
        }
    }

    func reset() {
        title = ""
        description = ""
        category = .cafe
        rating = 0
        latitude = ""
        longitude = ""
        address = ""
        best = ""
        bestTime = ""
        priceLevel = 0
        selectedImages = []
        error = nil
    }
}

extension NSImage {
    func jpegData(compressionQuality: CGFloat = 0.8) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
