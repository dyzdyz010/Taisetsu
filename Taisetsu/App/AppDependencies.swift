import Observation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    let repository: AnniversaryRepository
    let calendarSyncRepository: CalendarSyncRepository
    let calendarPromptCoordinator: CalendarSyncPromptCoordinator
    let reconciliationCoordinator: ReconciliationCoordinator

    init(container: ModelContainer) throws {
        let context = ModelContext(container)
        try DefaultCategorySeeder.seed(in: context)
        repository = AnniversaryRepository(context: context)
        calendarSyncRepository = CalendarSyncRepository(context: context)
        let calendarSyncService = CalendarAutoSyncService(
            client: EventStoreClient(), repository: calendarSyncRepository)
        reconciliationCoordinator = ReconciliationCoordinator(
            repository: repository,
            calendarSyncService: calendarSyncService,
            calendarSyncRepository: calendarSyncRepository
        )
        calendarPromptCoordinator = CalendarSyncPromptCoordinator(
            repository: repository,
            reconciliationCoordinator: reconciliationCoordinator
        )
    }
}
