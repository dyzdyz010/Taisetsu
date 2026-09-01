import Foundation
import Testing

@testable import TaisetsuCore

struct WatchSnapshotStoreTests {
    @Test func writtenSnapshotRoundTripsFromAnInjectedDirectory() throws {
        try withTemporaryStore { store in
            let snapshot = snapshot()
            try store.write(snapshot)

            #expect(try store.read() == snapshot)
        }
    }

    @Test func aSnapshotFromAFutureSchemaIsRejectedRatherThanRenderedWrong() throws {
        try withTemporaryStore { store in
            let future = WatchSnapshot(
                schemaVersion: WatchSnapshot.currentSchemaVersion + 1,
                generatedAt: Date(timeIntervalSince1970: 100),
                timeZoneIdentifier: "UTC",
                localeIdentifier: "zh-Hans",
                events: []
            )
            try Data(WatchSnapshot.encoder().encode(future)).write(to: fileURL(in: store))

            #expect(throws: WatchSnapshotStoreError.unsupportedSchemaVersion) { try store.read() }
        }
    }

    @Test func rewritingReplacesThePreviousSnapshot() throws {
        try withTemporaryStore { store in
            try store.write(snapshot())
            let replacement = WatchSnapshot(
                generatedAt: Date(timeIntervalSince1970: 500),
                timeZoneIdentifier: "Asia/Shanghai",
                localeIdentifier: "zh-Hans",
                events: []
            )
            try store.write(replacement)

            #expect(try store.read() == replacement)
        }
    }

    @Test func snapshotWritingUsesProtectionAvailableAfterFirstUnlock() {
        #expect(
            WatchSnapshotStore.writeOptions == [
                .atomic,
                .completeFileProtectionUntilFirstUserAuthentication,
            ]
        )
    }

    private func withTemporaryStore(_ body: (WatchSnapshotStore) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "TaisetsuWatchSnapshotTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(WatchSnapshotStore(directoryURL: directory))
    }

    private func fileURL(in store: WatchSnapshotStore) -> URL {
        store.directoryURL.appending(path: WatchSnapshotStore.fileName)
    }

    private func snapshot() -> WatchSnapshot {
        WatchSnapshot(
            generatedAt: Date(timeIntervalSince1970: 100),
            timeZoneIdentifier: "UTC",
            localeIdentifier: "zh-Hans",
            events: [
                WatchEventSnapshot(
                    id: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!,
                    title: "生日",
                    originalDate: Date(timeIntervalSince1970: 0),
                    upcomingDates: [Date(timeIntervalSince1970: 86_400)],
                    previousDate: nil,
                    isAllDay: true,
                    displayMode: .countdown,
                    categorySymbolName: "birthday.cake",
                    categoryColorToken: "purple",
                    isPinned: true,
                    isVisibleInWidget: true
                )
            ]
        )
    }
}
