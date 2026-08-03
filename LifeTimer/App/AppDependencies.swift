import Observation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    let repository: AnniversaryRepository

    init(container: ModelContainer) throws {
        let context = ModelContext(container)
        try DefaultCategorySeeder.seed(in: context)
        repository = AnniversaryRepository(context: context)
    }
}
