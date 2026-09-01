import Foundation

public enum WatchSnapshotStoreError: Error, Equatable {
    case unsupportedSchemaVersion
    case appGroupUnavailable
}

/// Watch-side mirror of `WidgetSnapshotStore`.
///
/// App Groups do not span devices, so this container is the watch's own; it holds whatever the
/// iPhone last pushed over WatchConnectivity and is the only thing the complication reads.
public struct WatchSnapshotStore: Sendable {
    public static let fileName = "watch-events.json"
    public static let writeOptions: Data.WritingOptions = [
        .atomic,
        .completeFileProtectionUntilFirstUserAuthentication,
    ]

    public let directoryURL: URL

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    public init?() {
        guard
            let directory = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppConfiguration.appGroupIdentifier
            )
        else { return nil }
        directoryURL = directory
    }

    public func write(_ snapshot: WatchSnapshot) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try WatchSnapshot.encoder().encode(snapshot)
        try data.write(to: fileURL, options: Self.writeOptions)
    }

    public func read() throws -> WatchSnapshot {
        let data = try Data(contentsOf: fileURL)
        let snapshot = try WatchSnapshot.decoder().decode(WatchSnapshot.self, from: data)
        guard snapshot.schemaVersion == WatchSnapshot.currentSchemaVersion else {
            throw WatchSnapshotStoreError.unsupportedSchemaVersion
        }
        return snapshot
    }

    private var fileURL: URL { directoryURL.appending(path: Self.fileName) }
}
