import SwiftUI

enum CategoryStyle {
    static func color(for token: String) -> Color {
        switch token {
        case "orange": .orange
        case "pink": .pink
        case "purple": .purple
        case "green": .green
        case "red": .red
        default: .blue
        }
    }
}
