import Observation
import SwiftUI
import TaisetsuCore

@MainActor
@Observable
final class CalendarSyncPromptCoordinator {
    private let repository: AnniversaryRepository
    private let reconciliationCoordinator: ReconciliationCoordinator
    var isPresented = false

    init(repository: AnniversaryRepository, reconciliationCoordinator: ReconciliationCoordinator) {
        self.repository = repository
        self.reconciliationCoordinator = reconciliationCoordinator
    }

    func consider(afterSaving record: AnniversaryRecord, isNew: Bool) {
        guard isNew, repository.fetch().count == 1 else { return }
        let settings = reconciliationCoordinator.calendarSettings
        guard !settings.enabled, settings.backoff.isEligible(at: .now) else { return }
        isPresented = true
    }

    func enable() async {
        var settings = reconciliationCoordinator.calendarSettings
        settings.enabled = true
        try? reconciliationCoordinator.saveCalendarSettings(settings)
        isPresented = false
        await reconciliationCoordinator.reconcile()
    }

    func later() {
        var settings = reconciliationCoordinator.calendarSettings
        settings.backoff.recordDeferral(at: .now)
        try? reconciliationCoordinator.saveCalendarSettings(settings)
        isPresented = false
    }

    func neverRemind() {
        var settings = reconciliationCoordinator.calendarSettings
        settings.backoff.neverRemind()
        try? reconciliationCoordinator.saveCalendarSettings(settings)
        isPresented = false
    }
}

struct CalendarSyncPromptView: View {
    @Environment(\.dismiss) private var dismiss
    let prompt: CalendarSyncPromptCoordinator

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                Text("Keep Important Days in Calendar")
                    .font(.title2.bold())
                Text(
                    "Taisetsu can automatically keep your important days in a dedicated Calendar. You can change the scope later in Settings."
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                Button("Enable Automatic Sync") { Task { await prompt.enable() } }
                    .buttonStyle(.borderedProminent)
                Button("Remind Me Later") { prompt.later() }
                Button("Never Remind Again", role: .destructive) { prompt.neverRemind() }
            }
            .padding(28)
            .navigationTitle("Calendar Sync")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
