import SwiftUI

struct SpotListView: View {
    @StateObject private var viewModel = SpotsViewModel()
    @State private var showingAddSpot = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.spots.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.spots.isEmpty {
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
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.spots) { spot in
                            SpotRowView(spot: spot)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteSpot(spot)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 300)
        .background(Color.background)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSpot = true }) {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .automatic) {
                Button(action: {
                    Task { await viewModel.fetchSpots() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $showingAddSpot) {
            AddSpotView(onComplete: {
                showingAddSpot = false
                Task { await viewModel.fetchSpots() }
            })
        }
        .task {
            await viewModel.fetchSpots()
        }
    }
}

struct SpotRowView: View {
    let spot: Spot

    var body: some View {
        HStack(spacing: 12) {
            if let primaryImage = spot.images.first(where: { $0.isPrimary }) ?? spot.images.first {
                AsyncImage(url: URL(string: primaryImage.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.categoryColor(spot.category))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.categoryColor(spot.category))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text(String(spot.title.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(spot.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    if let rating = spot.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }

                HStack {
                    Text(spot.category.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.categoryColor(spot.category))
                        .foregroundColor(.white)
                        .cornerRadius(4)

                    if let priceLevel = spot.priceLevel {
                        Text(String(repeating: "$", count: priceLevel))
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                if let description = spot.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(Color.card)
        .cornerRadius(12)
    }
}

#Preview {
    SpotListView()
}
