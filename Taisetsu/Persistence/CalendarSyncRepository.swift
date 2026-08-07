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

    func upsert(entry: CalendarSyncEntry) throws {
        let model =
            (try? context.fetch(FetchDescriptor<CalendarSyncEntryModel>()))?
            .first { $0.anniversaryID == entry.anniversaryID && $0.occurrenceKey == entry.occurrenceKey }
            ?? {
                let value = CalendarSyncEntryModel(entry: entry)
                context.insert(value)
                return value
            }()
        model.eventIdentifier = entry.eventIdentifier
        model.calendarIdentifier = entry.calendarIdentifier
        model.occurrenceDate = entry.occurrenceDate
        model.lastSyncedAt = entry.lastSyncedAt
        model.statusRaw = entry.status.rawValue
        model.errorMessage = entry.errorMessage
        try context.save()
    }

    func delete(entry: CalendarSyncEntry) throws {
        guard
            let model = (try? context.fetch(FetchDescriptor<CalendarSyncEntryModel>()))?
                .first(where: {
                    $0.anniversaryID == entry.anniversaryID && $0.occurrenceKey == entry.occurrenceKey
                })
        else { return }
        context.delete(model)
        try context.save()
    }

    func deleteEntries(for anniversaryID: UUID) throws {
        for model in (try? context.fetch(FetchDescriptor<CalendarSyncEntryModel>()))?.filter({
            $0.anniversaryID == anniversaryID
        }) ?? [] {
            context.delete(model)
        }
        try context.save()
    }

    func deleteEntries(notMatching keys: Set<String>, for anniversaryID: UUID) throws -> [CalendarSyncEntry] {
        let stale = entries(for: anniversaryID).filter { !keys.contains($0.occurrenceKey) }
        for entry in stale { try delete(entry: entry) }
        return stale
    }

    private func settingsModel() -> CalendarSyncSettingsModel? {
        (try? context.fetch(FetchDescriptor<CalendarSyncSettingsModel>()))?.first { $0.id == "default" }
    }
}
