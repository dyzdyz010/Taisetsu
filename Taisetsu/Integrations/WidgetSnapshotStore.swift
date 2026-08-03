import Foundation
import TaisetsuCore

struct WidgetSnapshotStore: Sendable {
    static let fileName = "upcoming-events.json"
    let directoryURL: URL

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    init?() {
        guard
            let directory = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppConfiguration.appGroupIdentifier
            )
        else { return nil }
        directoryURL = directory
    }

    func write(_ snapshot: WidgetSnapshot) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try JSONEncoder.taisetsu.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
    }

    func read() throws -> WidgetSnapshot {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.taisetsu.decode(WidgetSnapshot.self, from: data)
    }

    private var fileURL: URL { directoryURL.appending(path: Self.fileName) }
}

extension JSONEncoder {
    fileprivate static var taisetsu: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    fileprivate static var taisetsu: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
