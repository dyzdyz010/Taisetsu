import Foundation
import Observation
import TaisetsuCore
import WidgetKit

@MainActor
@Observable
final class ReconciliationCoordinator {
    private let repository: AnniversaryRepository
    private let reminderScheduler: ReminderScheduler
    private let notificationClient: NotificationCenterClientProtocol
    private let calendarExportService: CalendarExportService
    private let calendarSyncService: CalendarAutoSyncService?
    private let calendarSyncRepository: CalendarSyncRepository?
    private let snapshotStore: WidgetSnapshotStore?

    private(set) var lastError: String?
    private(set) var lastCalendarSyncSummary: CalendarSyncSummary?

    init(
        repository: AnniversaryRepository,
        reminderScheduler: ReminderScheduler = ReminderScheduler(),
        notificationClient: NotificationCenterClientProtocol = NotificationCenterClient(),
        calendarExportService: CalendarExportService = CalendarExportService(),
        calendarSyncService: CalendarAutoSyncService? = nil,
        calendarSyncRepository: CalendarSyncRepository? = nil,
        snapshotStore: WidgetSnapshotStore? = WidgetSnapshotStore()
    ) {
        self.repository = repository
        self.reminderScheduler = reminderScheduler
        self.notificationClient = notificationClient
        self.calendarExportService = calendarExportService
        self.calendarSyncService = calendarSyncService
        self.calendarSyncRepository = calendarSyncRepository
        self.snapshotStore = snapshotStore
    }

    func reconcile() async {
        let records = repository.fetch()
        do {
            if let snapshotStore {
                let snapshot = try WidgetSnapshot.make(
                    records: records,
                    relativeTo: .now,
                    timeZone: .current,
                    locale: .current
                )
                try snapshotStore.write(snapshot)
                WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.widgetKind)
            }
            try await reminderScheduler.reconcile(records: records, client: notificationClient)
            if let calendarSyncService, let calendarSyncRepository {
                var calendarSettings = calendarSyncRepository.loadSettings()
                lastCalendarSyncSummary = try await calendarSyncService.reconcile(
                    records: records,
                    settings: calendarSettings
                )
                if lastCalendarSyncSummary?.errorCount == 0, calendarSettings.enabled {
                    calendarSettings.lastSuccessfulSync = .now
                    try calendarSyncRepository.save(settings: calendarSettings)
                }
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func exportToCalendar(_ record: AnniversaryRecord) async throws {
        let identifier = try await calendarExportService.export(record: record)
        var draft = AnniversaryDraft(record: record)
        draft.calendarEventIdentifier = identifier
        _ = try repository.save(draft: draft)
        await reconcile()
    }

    var calendarSettings: CalendarSyncSettings {
        calendarSyncRepository?.loadSettings() ?? CalendarSyncSettings()
    }

    func saveCalendarSettings(_ settings: CalendarSyncSettings) throws {
        try calendarSyncRepository?.save(settings: settings)
    }

    func calendarEntriesCount() -> Int {
        calendarSyncRepository?.entries().count ?? 0
    }
}
