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
    private var isReconciling = false
    private var needsReconciliation = false
    private var reconciliationWaiters: [CheckedContinuation<Void, Never>] = []

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
        needsReconciliation = true
        if isReconciling {
            await withCheckedContinuation { continuation in
                reconciliationWaiters.append(continuation)
            }
            return
        }
        isReconciling = true

        while needsReconciliation {
            needsReconciliation = false
            await performReconciliation()
        }
        isReconciling = false
        let waiters = reconciliationWaiters
        reconciliationWaiters.removeAll(keepingCapacity: true)
        for waiter in waiters {
            waiter.resume()
        }
    }

    private func performReconciliation() async {
        let records = repository.fetch()
        let referenceDate = Date.now
        let timeZone = TimeZone.current
        let locale = Locale.current
        let snapshotStore = snapshotStore
        let reminderScheduler = reminderScheduler
        do {
            let plan = try await Task.detached(priority: .utility) {
                let plan = try ReconciliationPlan.make(
                    records: records,
                    referenceDate: referenceDate,
                    timeZone: timeZone,
                    locale: locale,
                    includesWidgetSnapshot: snapshotStore != nil,
                    reminderScheduler: reminderScheduler
                )
                if let snapshot = plan.widgetSnapshot {
                    try snapshotStore?.write(snapshot)
                }
                return plan
            }.value
            if plan.widgetSnapshot != nil {
                WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.widgetKind)
            }
            try await reminderScheduler.apply(plan.reminders, client: notificationClient)
            if let calendarSyncService, let calendarSyncRepository {
                var calendarSettings = calendarSyncRepository.loadSettings()
                lastCalendarSyncSummary = try await calendarSyncService.reconcile(
                    records: records,
                    settings: calendarSettings
                )
                if lastCalendarSyncSummary?.errorCount == 0, calendarSettings.enabled {
                    calendarSettings.lastSuccessfulSync = referenceDate
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
