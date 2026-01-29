# SpotDrop macOS

Native SwiftUI macOS application for adding spots to SpotDrop.

## Tech Stack

- **UI:** SwiftUI
- **Architecture:** MVVM with Combine
- **Networking:** URLSession
- **Storage:** Keychain for tokens

## Project Structure

```
SpotDrop/
├── SpotDrop/
│   ├── SpotDropApp.swift         # @main app entry point
│   ├── ContentView.swift         # Root view with navigation
│   │
│   ├── Core/                     # Core infrastructure
│   │   ├── Network/
│   │   │   └── APIClient.swift   # URLSession HTTP client (singleton)
│   │   ├── Models/
│   │   │   └── Models.swift      # Shared data models (Codable)
│   │   └── Storage/
│   │       └── KeychainManager.swift  # Secure token storage
│   │
│   ├── Features/                 # Feature modules (MVVM)
│   │   ├── Auth/
│   │   │   ├── LoginView.swift
│   │   │   └── AuthViewModel.swift
│   │   └── Spots/
│   │       ├── SpotListView.swift
│   │       ├── SpotRowView.swift
│   │       ├── AddSpotView.swift
│   │       ├── SpotsViewModel.swift
│   │       └── AddSpotViewModel.swift
│   │
│   ├── UI/                       # Design system
│   │   └── Theme.swift           # Colors, styles, modifiers
│   │
│   └── Assets.xcassets/          # App icons and colors
│
├── SpotDropTests/                # Unit tests
└── SpotDropUITests/              # UI tests
```

## Structure Requirements (MUST FOLLOW)

When adding new features, you MUST follow these patterns:

### Adding a New Feature (e.g., "comments")

1. **Model** - Add to `Core/Models/Models.swift`:
   ```swift
   struct Comment: Codable, Identifiable {
       let id: Int
       let content: String
       let userId: Int
       let spotId: Int
       let createdAt: String

       enum CodingKeys: String, CodingKey {
           case id, content
           case userId = "user_id"
           case spotId = "spot_id"
           case createdAt = "created_at"
       }
   }

   struct CreateCommentRequest: Codable {
       let content: String
       let spotId: Int

       enum CodingKeys: String, CodingKey {
           case content
           case spotId = "spot_id"
       }
   }
   ```

2. **API Methods** - Add to `Core/Network/APIClient.swift`:
   ```swift
   func getComments(spotId: Int) async throws -> [Comment] {
       return try await request(
           endpoint: "/spots/\(spotId)/comments",
           method: "GET"
       )
   }

   func createComment(_ request: CreateCommentRequest) async throws -> Comment {
       return try await request(
           endpoint: "/comments",
           method: "POST",
           body: request
       )
   }
   ```

3. **ViewModel** - Create `Features/Comments/CommentsViewModel.swift`:
   ```swift
   import Foundation
   import Combine

   @MainActor
   class CommentsViewModel: ObservableObject {
       @Published var comments: [Comment] = []
       @Published var isLoading = false
       @Published var errorMessage: String?

       private let apiClient: APIClient

       init(apiClient: APIClient = .shared) {
           self.apiClient = apiClient
       }

       func fetchComments(spotId: Int) async {
           isLoading = true
           defer { isLoading = false }

           do {
               comments = try await apiClient.getComments(spotId: spotId)
           } catch {
               errorMessage = error.localizedDescription
           }
       }

       func addComment(content: String, spotId: Int) async {
           do {
               let request = CreateCommentRequest(content: content, spotId: spotId)
               let comment = try await apiClient.createComment(request)
               comments.append(comment)
           } catch {
               errorMessage = error.localizedDescription
           }
       }
   }
   ```

4. **View** - Create `Features/Comments/CommentsView.swift`:
   ```swift
   import SwiftUI

   struct CommentsView: View {
       let spotId: Int
       @StateObject private var viewModel = CommentsViewModel()
       @State private var newComment = ""

       var body: some View {
           VStack {
               List(viewModel.comments) { comment in
                   CommentRowView(comment: comment)
               }

               HStack {
                   TextField("Add a comment...", text: $newComment)
                       .textFieldStyle(.roundedBorder)

                   Button("Post") {
                       Task {
                           await viewModel.addComment(content: newComment, spotId: spotId)
                           newComment = ""
                       }
                   }
                   .buttonStyle(PrimaryButtonStyle())
               }
               .padding()
           }
           .task {
               await viewModel.fetchComments(spotId: spotId)
           }
       }
   }
   ```

5. **Row View** - Create `Features/Comments/CommentRowView.swift`:
   ```swift
   import SwiftUI

   struct CommentRowView: View {
       let comment: Comment

       var body: some View {
           VStack(alignment: .leading, spacing: 4) {
               Text(comment.content)
                   .foregroundColor(.textPrimary)
               Text(comment.createdAt)
                   .font(.caption)
                   .foregroundColor(.textSecondary)
           }
           .padding()
           .modifier(CardStyle())
       }
   }
   ```

### MVVM Architecture Pattern

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    View     │────▶│  ViewModel  │────▶│  APIClient  │
│  (SwiftUI)  │◀────│ (@MainActor)│◀────│  (Network)  │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       │                   │                   ▼
       │                   │            ┌─────────────┐
       │                   └───────────▶│   Models    │
       │                                │  (Codable)  │
       │                                └─────────────┘
       │
       ▼
┌─────────────┐
│   Theme     │
│  (Styles)   │
└─────────────┘
```

### File Organization

| Directory | Purpose | Pattern |
|-----------|---------|---------|
| `Core/Network/` | HTTP client | Singleton `APIClient.shared` |
| `Core/Models/` | Data structures | `Codable`, `Identifiable` |
| `Core/Storage/` | Persistence | Singleton `KeychainManager.shared` |
| `Features/<Name>/` | Feature module | `*View.swift`, `*ViewModel.swift` |
| `UI/` | Design system | Colors, styles, modifiers |

### Naming Conventions

- **Views:** `*View.swift` (e.g., `SpotListView.swift`)
- **ViewModels:** `*ViewModel.swift` (e.g., `SpotsViewModel.swift`)
- **Row Views:** `*RowView.swift` (e.g., `SpotRowView.swift`)
- **Models:** Singular nouns (e.g., `Spot`, `Comment`)
- **Requests:** `*Request` suffix (e.g., `CreateSpotRequest`)

### ViewModel Pattern

```swift
@MainActor
class FeatureViewModel: ObservableObject {
    // Published state
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Dependencies (injected via init)
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // Async methods
    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await apiClient.getItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### View Pattern

```swift
struct FeatureView: View {
    // ViewModel
    @StateObject private var viewModel = FeatureViewModel()

    // Local state
    @State private var showingSheet = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.items) { item in
                    ItemRowView(item: item)
                }
            }
        }
        .task {
            await viewModel.fetchItems()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

## Quick Start

```bash
# Open in Xcode
open SpotDrop.xcodeproj

# Build
xcodebuild -scheme SpotDrop -configuration Debug build

# Run tests
xcodebuild test -scheme SpotDrop -destination 'platform=macOS'
```

## Features

- User authentication (login/register)
- Add new spots with:
  - Title, description
  - Category selection
  - Star rating
  - Location (coordinates)
  - Images (1-5)
  - Conditional fields (best, best time, price)
- View user's spots
- Secure token storage in Keychain

## Design System

Dark theme matching web app:

| Token | Value | Usage |
|-------|-------|-------|
| `.background` | #0F172A | Window background |
| `.card` | #1E293B | Card backgrounds |
| `.textPrimary` | white | Primary text |
| `.textSecondary` | #94A3B8 | Secondary text |

### Styles

```swift
// Card modifier
.modifier(CardStyle())

// Button styles
.buttonStyle(PrimaryButtonStyle())
.buttonStyle(SecondaryButtonStyle())
```

### Category Colors

```swift
extension SpotCategory {
    var color: Color {
        switch self {
        case .cafe: return Color(hex: "22C55E")
        case .restaurant: return Color(hex: "F97316")
        case .bar: return Color(hex: "A855F7")
        case .park: return Color(hex: "14B8A6")
        case .museum: return Color(hex: "3B82F6")
        case .shop: return Color(hex: "EC4899")
        case .other: return Color(hex: "6B7280")
        }
    }
}
```

## Agents

- `@architect` - SwiftUI architecture, MVVM patterns
- `@developer` - Views, ViewModels, networking
- `@debugger` - macOS debugging, Keychain issues
- `@reviewer` - Swift/SwiftUI code review

## Skills

- `/build` - Build macOS app
- `/func-start` - Run in simulator
- `/lint` - Run SwiftLint
- `/test` - Run XCTests
