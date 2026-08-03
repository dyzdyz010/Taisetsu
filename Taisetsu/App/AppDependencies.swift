import Observation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    let repository: AnniversaryRepository
    let reconciliationCoordinator: ReconciliationCoordinator

    init(container: ModelContainer) throws {
        let context = ModelContext(container)
        try DefaultCategorySeeder.seed(in: context)
        repository = AnniversaryRepository(context: context)
        reconciliationCoordinator = ReconciliationCoordinator(repository: repository)
    }
}
