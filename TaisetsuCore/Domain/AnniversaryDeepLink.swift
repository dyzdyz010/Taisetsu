import Foundation

/// The one definition of how a surface points at a single important day.
///
/// Widgets and complications build these URLs, the watch app parses them, and reminders carry the
/// same identifier in their notification payload. Keeping producer and consumer on one definition
/// is what stops a link from being emitted in a shape nothing routes.
public enum AnniversaryDeepLink {
    public static let scheme = "taisetsu"
    public static let host = "anniversary"
    /// Key under which a reminder notification carries the day it is about.
    public static let notificationUserInfoKey = "anniversaryID"

    public static func url(for id: UUID) -> URL? {
        URL(string: "\(scheme)://\(host)/\(id.uuidString)")
    }

    public static func anniversaryID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host == host else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }

    public static func anniversaryID(fromNotification userInfo: [AnyHashable: Any]) -> UUID? {
        guard let raw = userInfo[notificationUserInfoKey] as? String else { return nil }
        return UUID(uuidString: raw)
    }
}
