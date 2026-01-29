import SwiftUI

extension Color {
    // Light theme colors
    static let background = Color(hex: "#F8FAFC")       // Light gray background
    static let sidebar = Color(hex: "#F1F5F9")          // Slightly darker sidebar
    static let card = Color.white                        // White cards
    static let cardHover = Color(hex: "#F1F5F9")        // Hover state
    static let border = Color(hex: "#E2E8F0")           // Border color

    // Text colors
    static let textPrimary = Color(hex: "#1E293B")      // Dark text
    static let textSecondary = Color(hex: "#64748B")    // Secondary text

    // Accent colors
    static let accent = Color(hex: "#6366F1")           // hsl(239 84% 67%) - Indigo
    static let accentLight = Color(hex: "#C084FC")      // Purple/Violet
    static let accentBackground = Color(hex: "#EEF2FF") // Light indigo background

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static func categoryColor(_ category: String) -> Color {
        guard let cat = SpotCategory(rawValue: category) else {
            return Color(hex: "#6B7280")
        }
        return Color(hex: cat.color)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.card)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.accent)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.accentBackground)
            .foregroundColor(.accent)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
