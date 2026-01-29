import SwiftUI

struct AddSpotView: View {
    @StateObject private var viewModel = AddSpotViewModel()
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add New Spot")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.card)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Section("Basic Info") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Title *", text: $viewModel.title)
                                .textFieldStyle(.roundedBorder)

                            TextField("Description", text: $viewModel.description, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...5)

                            Picker("Category", selection: $viewModel.category) {
                                ForEach(SpotCategory.allCases) { category in
                                    Text(category.label).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    Section("Location") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                TextField("Latitude *", text: $viewModel.latitude)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Longitude *", text: $viewModel.longitude)
                                    .textFieldStyle(.roundedBorder)
                            }

                            TextField("Address", text: $viewModel.address)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Section("Details") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Rating")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                RatingPicker(rating: $viewModel.rating)
                            }

                            TextField("Best (e.g., Cappuccino)", text: $viewModel.best)
                                .textFieldStyle(.roundedBorder)

                            TextField("Best time (e.g., Morning)", text: $viewModel.bestTime)
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                Text("Price Level")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                PricePicker(priceLevel: $viewModel.priceLevel)
                            }
                        }
                    }

                    Section("Images") {
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

                            if viewModel.selectedImages.count < 5 {
                                Button(action: viewModel.addImage) {
                                    Label("Add Images", systemImage: "photo.badge.plus")
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }

                            Text("\(viewModel.selectedImages.count)/5 images")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        Task {
                            if let _ = await viewModel.createSpot() {
                                onComplete()
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Spot")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
                .padding()
            }
        }
        .frame(width: 450, height: 600)
        .background(Color.background)
    }
}

struct Section<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)
            content
        }
    }
}

struct RatingPicker: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        rating = Double(star)
                    }
            }
        }
    }
}

struct PricePicker: View {
    @Binding var priceLevel: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...4, id: \.self) { level in
                Text("$")
                    .fontWeight(.bold)
                    .foregroundColor(level <= priceLevel ? .green : .textSecondary)
                    .onTapGesture {
                        priceLevel = level
                    }
            }
        }
    }
}

#Preview {
    AddSpotView(onComplete: {})
}
