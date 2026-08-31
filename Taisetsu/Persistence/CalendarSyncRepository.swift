import Foundation
import SwiftData
import TaisetsuCore

@MainActor
final class CalendarSyncRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadSettings() -> CalendarSyncSettings {
        guard let model = settingsModel() else { return CalendarSyncSettings() }
        return model.map()
    }

    func save(settings: CalendarSyncSettings) throws {
        let model =
            settingsModel()
            ?? {
                let value = CalendarSyncSettingsModel()
                context.insert(value)
                return value
            }()
        model.update(from: settings)
        try context.save()
    }

    func entries(for anniversaryID: UUID? = nil) -> [CalendarSyncEntry] {
        let models = (try? context.fetch(FetchDescriptor<CalendarSyncEntryModel>())) ?? []
        return
            models
            .filter { anniversaryID == nil || $0.anniversaryID == anniversaryID }
            .map { $0.map() }
            .sorted { $0.occurrenceDate < $1.occurrenceDate }
    }

    func replaceEntries(with entries: [CalendarSyncEntry]) throws {
        let existing = try context.fetch(FetchDescriptor<CalendarSyncEntryModel>())
        var modelsByID = Dictionary(grouping: existing) { model in
            "\(model.anniversaryID.uuidString):\(model.occurrenceKey)"
        }

        for entry in entries {
            let matching = modelsByID.removeValue(forKey: entry.id) ?? []
            let model = matching.first ?? CalendarSyncEntryModel(entry: entry)
            if model.modelContext == nil { context.insert(model) }
            model.update(from: entry)
            for duplicate in matching.dropFirst() {
                context.delete(duplicate)
            }
        }
        for stale in modelsByID.values.joined() {
            context.delete(stale)
        }
        try context.save()
    }

    private func settingsModel() -> CalendarSyncSettingsModel? {
        (try? context.fetch(FetchDescriptor<CalendarSyncSettingsModel>()))?.first { $0.id == "default" }
    }
}
