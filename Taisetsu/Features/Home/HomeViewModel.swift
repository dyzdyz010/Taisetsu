import Foundation
import Observation
import TaisetsuCore

enum HomeContentState: Equatable {
    case loading
    case empty
    case content
    case failed(String)
}

@MainActor
@Observable
final class HomeViewModel {
    typealias Project = ([AnniversaryRecord], Date, TimeZone) throws -> AnniversarySections

    private let repository: AnniversaryRepository
    private let now: () -> Date
    private let project: Project
    private var records: [AnniversaryRecord] = []
    private var allSections = AnniversarySections(pinned: [], upcoming: [], ongoing: [], ended: [])
    private var projectedState = HomeContentState.loading

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
    private(set) var categories: [CategoryModel] = []
    private(set) var tags: [TagModel] = []
    private(set) var sections = AnniversarySections(pinned: [], upcoming: [], ongoing: [], ended: [])

    var hero: AnniversaryPresentation? { sections.all.first }

    init(
        repository: AnniversaryRepository,
        now: @escaping () -> Date = { .now },
        project: @escaping Project = { records, referenceDate, timeZone in
            try AnniversaryOrdering().sections(
                records: records,
                relativeTo: referenceDate,
                timeZone: timeZone
            )
        }
    ) {
        self.repository = repository
        self.now = now
        self.project = project
    }

    func load() {
        records = repository.fetch()
        categories = repository.categories()
        tags = repository.tags()
        do {
            allSections = try project(records, now(), .current)
            projectedState = records.isEmpty ? .empty : .content
        } catch {
            allSections = AnniversarySections(pinned: [], upcoming: [], ongoing: [], ended: [])
            projectedState = .failed(error.localizedDescription)
        }
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
        sections = AnniversarySections(
            pinned: allSections.pinned.filter { filter.matches($0.record) },
            upcoming: allSections.upcoming.filter { filter.matches($0.record) },
            ongoing: allSections.ongoing.filter { filter.matches($0.record) },
            ended: allSections.ended.filter { filter.matches($0.record) }
        )
        state = projectedState
    }
}
