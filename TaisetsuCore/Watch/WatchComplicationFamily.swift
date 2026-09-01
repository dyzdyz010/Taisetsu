import Foundation

/// The accessory families a watch complication renders into, expressed without importing WidgetKit
/// so the selection rule stays testable from the iOS test target.
public enum WatchComplicationFamily: CaseIterable, Sendable {
    case circular
    case corner
    case inline
    case rectangular

    public var capacity: Int {
        switch self {
        case .circular, .corner, .inline: 1
        case .rectangular: 2
        }
    }
}
