//
//  ContentView.swift
//  SpotDrop
//

import SwiftUI

enum DetailViewMode: Equatable {
    case none
    case spotDetail(Spot)
    case addSpot

    static func == (lhs: DetailViewMode, rhs: DetailViewMode) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.addSpot, .addSpot):
            return true
        case (.spotDetail(let lSpot), .spotDetail(let rSpot)):
            return lSpot.id == rSpot.id
        default:
            return false
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            if authViewModel.isAuthenticated {
                MainView()
                    .environmentObject(authViewModel)
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .task {
            await authViewModel.checkAuth()
        }
    }
}

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var spotsViewModel = SpotsViewModel()
    @State private var detailMode: DetailViewMode = .none

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with navigation icons
            SidebarView()

            // List panel
            ListPanelView(
                spotsViewModel: spotsViewModel,
                detailMode: $detailMode
            )

            // Divider
            Rectangle()
                .fill(Color.border)
                .frame(width: 1)

            // Detail panel
            DetailPanelView(
                detailMode: $detailMode,
                spotsViewModel: spotsViewModel
            )
        }
        .background(Color.background)
        .task {
            await spotsViewModel.fetchSpots()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            // App icon
            VStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accent)
            }
            .frame(width: 70, height: 70)
            .background(Color.accentBackground)

            // Navigation items
            VStack(spacing: 8) {
                SidebarButton(icon: "map.fill", label: "Spots", isSelected: true)
                SidebarButton(icon: "star.fill", label: "Favorites", isSelected: false)
                SidebarButton(icon: "gearshape.fill", label: "Settings", isSelected: false)
            }
            .padding(.top, 20)

            Spacer()

            // User menu
            Menu {
                Text(authViewModel.user?.username ?? "User")
                Divider()
                Button("Logout") {
                    authViewModel.logout()
                }
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accent)
            }
            .menuStyle(.borderlessButton)
            .padding(.bottom, 20)
        }
        .frame(width: 70)
        .background(Color.sidebar)
    }
}

struct SidebarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .accent : .textSecondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(isSelected ? .accent : .textSecondary)
        }
        .frame(width: 60, height: 50)
        .background(isSelected ? Color.accentBackground : Color.clear)
        .cornerRadius(8)
    }
}

struct ListPanelView: View {
    @ObservedObject var spotsViewModel: SpotsViewModel
    @Binding var detailMode: DetailViewMode

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("LIST")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .tracking(2)

                Spacer()

                Button(action: {
                    detailMode = .addSpot
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accent)
                }
                .buttonStyle(.plain)

                Button(action: {
                    Task { await spotsViewModel.fetchSpots() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.accentBackground.opacity(0.5))

            // List content
            if spotsViewModel.isLoading && spotsViewModel.spots.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                Spacer()
            } else if spotsViewModel.spots.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.textSecondary)
                    Text("No spots yet")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text("Add your first spot!")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Button("Add Spot") {
                        detailMode = .addSpot
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(spotsViewModel.spots) { spot in
                            SpotRowView(
                                spot: spot,
                                isSelected: isSpotSelected(spot)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                detailMode = .spotDetail(spot)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        await spotsViewModel.deleteSpot(spot)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }

                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
            }
        }
        .frame(width: 320)
        .background(Color.card)
    }

    private func isSpotSelected(_ spot: Spot) -> Bool {
        if case .spotDetail(let selected) = detailMode {
            return selected.id == spot.id
        }
        return false
    }
}

struct SpotRowView: View {
    let spot: Spot
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let primaryImage = spot.images.first(where: { $0.isPrimary }) ?? spot.images.first {
                AsyncImage(url: URL(string: primaryImage.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.categoryColor(spot.category).opacity(0.2))
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.categoryColor(spot.category), lineWidth: 2)
                )
            } else {
                Circle()
                    .fill(Color.categoryColor(spot.category).opacity(0.2))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text(String(spot.title.prefix(1)))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.categoryColor(spot.category))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.categoryColor(spot.category), lineWidth: 2)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.categoryColor(spot.category))
                    .lineLimit(1)

                Text(spot.address ?? spot.category.uppercased())
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentBackground : Color.clear)
    }
}

struct DetailPanelView: View {
    @Binding var detailMode: DetailViewMode
    @ObservedObject var spotsViewModel: SpotsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DETAIL")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .tracking(2)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.accentBackground.opacity(0.5))

            // Content
            switch detailMode {
            case .none:
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: 64))
                        .foregroundColor(.textSecondary.opacity(0.5))
                    Text("Select a spot to view details")
                        .foregroundColor(.textSecondary)
                }
                Spacer()

            case .spotDetail(let spot):
                SpotDetailView(spot: spot)

            case .addSpot:
                AddSpotPanelView(
                    onComplete: {
                        detailMode = .none
                        Task { await spotsViewModel.fetchSpots() }
                    },
                    onCancel: {
                        detailMode = .none
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.card)
    }
}

struct SpotDetailView: View {
    let spot: Spot

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero image
                if let primaryImage = spot.images.first(where: { $0.isPrimary }) ?? spot.images.first {
                    AsyncImage(url: URL(string: primaryImage.url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.categoryColor(spot.category).opacity(0.2))
                    }
                    .frame(height: 280)
                    .frame(maxWidth: 400)
                    .clipped()
                    .cornerRadius(16)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.categoryColor(spot.category).opacity(0.2))
                        .frame(height: 280)
                        .frame(maxWidth: 400)
                        .overlay(
                            Text(String(spot.title.prefix(1)))
                                .font(.system(size: 72, weight: .bold))
                                .foregroundColor(Color.categoryColor(spot.category))
                        )
                }

                // Info section
                VStack(alignment: .leading, spacing: 16) {
                    // Title and rating
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(spot.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.accent)

                            if let address = spot.address {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                        }

                        Spacer()

                        if let rating = spot.rating {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                                        .foregroundColor(Color(hex: "#F59E0B"))
                                        .font(.system(size: 14))
                                }
                            }
                        }
                    }

                    // Category badge
                    HStack {
                        Text(spot.category.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.categoryColor(spot.category))
                            .foregroundColor(.white)
                            .cornerRadius(6)

                        if let priceLevel = spot.priceLevel {
                            HStack(spacing: 2) {
                                ForEach(1...4, id: \.self) { level in
                                    Text("$")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(level <= priceLevel ? Color(hex: "#22C55E") : .textSecondary.opacity(0.3))
                                }
                            }
                        }
                    }

                    // Description
                    if let description = spot.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.textPrimary)
                            .lineSpacing(4)
                    }

                    Divider()

                    // Details
                    VStack(spacing: 12) {
                        if let best = spot.best {
                            DetailRow(
                                icon: "star.circle.fill",
                                label: "Best",
                                value: best,
                                color: Color(hex: "#F59E0B")
                            )
                        }

                        if let bestTime = spot.bestTime {
                            DetailRow(
                                icon: "clock.fill",
                                label: "Best time",
                                value: bestTime,
                                color: Color(hex: "#6366F1")
                            )
                        }

                        DetailRow(
                            icon: "location.fill",
                            label: "Coordinates",
                            value: String(format: "%.4f, %.4f", spot.latitude, spot.longitude),
                            color: Color(hex: "#22C55E")
                        )
                    }

                    // Image gallery
                    if spot.images.count > 1 {
                        Divider()

                        Text("Photos")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(spot.images) { image in
                                    AsyncImage(url: URL(string: image.url)) { img in
                                        img
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.sidebar)
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 400, alignment: .leading)
            }
            .padding(32)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
        }
    }
}

struct AddSpotPanelView: View {
    @StateObject private var viewModel = AddSpotViewModel()
    let onComplete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("Add New Spot")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.textSecondary)
                }

                // Basic Info
                FormSection("Basic Info") {
                    VStack(alignment: .leading, spacing: 12) {
                        FormTextField("Title *", text: $viewModel.title)

                        FormTextField("Description", text: $viewModel.description, axis: .vertical)

                        HStack {
                            Text("Category")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Picker("", selection: $viewModel.category) {
                                ForEach(SpotCategory.allCases) { category in
                                    Text(category.label).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.accent)
                        }
                    }
                }

                // Location
                FormSection("Location") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            FormTextField("Latitude *", text: $viewModel.latitude)
                            FormTextField("Longitude *", text: $viewModel.longitude)
                        }
                        FormTextField("Address", text: $viewModel.address)
                    }
                }

                // Details
                FormSection("Details") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Rating")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            Spacer()
                            RatingPickerLight(rating: $viewModel.rating)
                        }

                        FormTextField("Best (e.g., Cappuccino)", text: $viewModel.best)
                        FormTextField("Best time (e.g., Morning)", text: $viewModel.bestTime)

                        HStack {
                            Text("Price Level")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            Spacer()
                            PricePickerLight(priceLevel: $viewModel.priceLevel)
                        }
                    }
                }

                // Images
                FormSection("Images") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !viewModel.selectedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                                        ZStack(alignment: .topTrailing) {
                                            Image(nsImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)

                                            Button(action: {
                                                viewModel.removeImage(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                            }
                                            .buttonStyle(.plain)
                                            .offset(x: 4, y: -4)
                                        }
                                    }
                                }
                            }
                        }

                        HStack {
                            if viewModel.selectedImages.count < 5 {
                                Button(action: viewModel.addImage) {
                                    Label("Add Images", systemImage: "photo.badge.plus")
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }

                            Spacer()

                            Text("\(viewModel.selectedImages.count)/5 images")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                // Error
                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                // Submit
                Button(action: {
                    Task {
                        if let _ = await viewModel.createSpot() {
                            onComplete()
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Spot")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isValid || viewModel.isLoading)
            }
            .padding(32)
        }
    }
}

struct FormSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)
            content
        }
        .padding(16)
        .background(Color.sidebar)
        .cornerRadius(12)
    }
}

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    init(_ placeholder: String, text: Binding<String>, axis: Axis = .horizontal) {
        self.placeholder = placeholder
        self._text = text
        self.axis = axis
    }

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color.card)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.border, lineWidth: 1)
            )
    }
}

struct RatingPickerLight: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                    .foregroundColor(Color(hex: "#F59E0B"))
                    .font(.system(size: 18))
                    .onTapGesture {
                        rating = Double(star)
                    }
            }
        }
    }
}

struct PricePickerLight: View {
    @Binding var priceLevel: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...4, id: \.self) { level in
                Text("$")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(level <= priceLevel ? Color(hex: "#22C55E") : .textSecondary.opacity(0.3))
                    .onTapGesture {
                        priceLevel = level
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
