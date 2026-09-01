import Foundation

/// The accessory families a watch complication renders into, expressed without importing WidgetKit
/// so the selection rule stays testable from the iOS test target.
public enum WatchComplicationFamily: CaseIterable, Sendable {
    case circular
    case corner
    case inline
    case rectangular

    /// Every family shows a single day.
    ///
    /// The rectangular card is wide enough for two rows, but two equally weighted rows of small
    /// text answer no question at a glance; one day with a real hierarchy does.
    public var capacity: Int { 1 }
}
