import Foundation
import LifeTimerCore
import Observation

enum HomeContentState: Equatable {
    case loading
    case empty
    case content
    case failed(String)
}

@MainActor
@Observable
final class HomeViewModel {
    private let repository: AnniversaryRepository
    private let now: () -> Date
    private var records: [AnniversaryRecord] = []

    var state = HomeContentState.loading
    var query = "" {
        didSet { rebuild() }
    }
    var categoryID: UUID? {
        didSet { rebuild() }
    }
    var requiredTagIDs: Set<UUID> = [] {
        didSet { rebuild() }
    }
    private(set) var sections = AnniversarySections(pinned: [], upcoming: [], ongoing: [], ended: [])

    var hero: AnniversaryPresentation? { sections.all.first }

    init(repository: AnniversaryRepository, now: @escaping () -> Date = { .now }) {
        self.repository = repository
        self.now = now
    }

    func load() {
        records = repository.fetch()
        rebuild()
    }

    func setPinned(id: UUID, isPinned: Bool) throws {
        try repository.setPinned(id: id, isPinned: isPinned)
        load()
    }

    func delete(id: UUID) throws {
        try repository.delete(id: id)
        load()
    }

    private func rebuild() {
        let filter = AnniversaryFilter(
            query: query,
            categoryID: categoryID,
            requiredTagIDs: requiredTagIDs
        )
        let filtered = records.filter(filter.matches)
        do {
            sections = try AnniversaryOrdering().sections(
                records: filtered,
                relativeTo: now(),
                timeZone: .current
            )
            state = filtered.isEmpty && records.isEmpty ? .empty : .content
        } catch {
            sections = AnniversarySections(pinned: [], upcoming: [], ongoing: [], ended: [])
            state = .failed(error.localizedDescription)
        }
    }
}
