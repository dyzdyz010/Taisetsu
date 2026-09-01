import SwiftUI

/// Matches the app and widget token mapping; each target carries its own copy because the
/// mapping lives above `TaisetsuCore`, which stays free of UI.
enum WatchCategoryStyle {
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
