import Foundation
import Testing

@testable import Taisetsu
@testable import TaisetsuCore

struct WidgetSnapshotStoreTests {
    @Test func writtenSnapshotRoundTripsFromAnInjectedDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "TaisetsuWidgetSnapshotTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WidgetSnapshotStore(directoryURL: directory)
        let snapshot = WidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 100),
            timeZoneIdentifier: "UTC",
            localeIdentifier: "zh-Hans",
            events: []
        )
        try store.write(snapshot)
        #expect(try store.read() == snapshot)
    }
}
