import Foundation
import TaisetsuCore
import WidgetKit

@MainActor
final class ReconciliationCoordinator {
    private let repository: AnniversaryRepository
    private let reminderScheduler: ReminderScheduler
    private let notificationClient: NotificationCenterClientProtocol
    private let calendarExportService: CalendarExportService
    private let snapshotStore: WidgetSnapshotStore?

    private(set) var lastError: String?

    init(
        repository: AnniversaryRepository,
        reminderScheduler: ReminderScheduler = ReminderScheduler(),
        notificationClient: NotificationCenterClientProtocol = NotificationCenterClient(),
        calendarExportService: CalendarExportService = CalendarExportService(),
        snapshotStore: WidgetSnapshotStore? = WidgetSnapshotStore()
    ) {
        self.repository = repository
        self.reminderScheduler = reminderScheduler
        self.notificationClient = notificationClient
        self.calendarExportService = calendarExportService
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
}
