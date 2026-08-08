import Foundation
import SwiftData
import TaisetsuCore

@MainActor
final class AnniversaryRepository {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(filter: AnniversaryFilter = AnniversaryFilter()) -> [AnniversaryRecord] {
        let descriptor = FetchDescriptor<AnniversaryModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? context.fetch(descriptor))?.map(map).filter(filter.matches) ?? []
    }

    @discardableResult
    func save(draft: AnniversaryDraft) throws -> AnniversaryRecord {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw AnniversaryValidationError.emptyTitle }
        guard draft.recurrenceUnit == nil || draft.recurrenceInterval > 0 else {
            throw AnniversaryValidationError.invalidRecurrenceInterval
        }

        let model: AnniversaryModel
        if let id = draft.id, let existing = allAnniversaries().first(where: { $0.id == id }) {
            model = existing
        } else {
            model = AnniversaryModel(id: draft.id ?? UUID(), title: title)
            context.insert(model)
        }
        model.title = title
        model.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        model.calendarKindRaw = draft.calendarKind.rawValue
        model.year = draft.date.year
        model.month = draft.date.month
        model.day = draft.date.day
        model.hour = draft.date.hour
        model.minute = draft.date.minute
        model.isLeapMonth = draft.date.isLeapMonth
        model.isAllDay = draft.isAllDay
        model.recurrenceUnitRaw = draft.recurrenceUnit?.rawValue
        model.recurrenceInterval = draft.recurrenceInterval
        model.displayModeRaw = draft.displayMode.rawValue
        model.isPinned = draft.isPinned
        model.isVisibleInWidget = draft.isVisibleInWidget
        model.calendarEventIdentifier = draft.calendarEventIdentifier
        model.category = allCategories().first(where: { $0.id == draft.categoryID })
        model.tags = allTags().filter { draft.tagIDs.contains($0.id) }
        model.reminders = draft.reminders.map {
            let reminder = ReminderRuleModel(
                id: $0.id,
                offsetMinutes: $0.offsetMinutes,
                timeOfDayMinutes: $0.timeOfDayMinutes,
                isEnabled: $0.isEnabled
            )
            reminder.anniversary = model
            return reminder
        }
        model.updatedAt = .now
        try context.save()
        return map(model)
    }

    func delete(id: UUID) throws {
        guard let model = allAnniversaries().first(where: { $0.id == id }) else { return }
        context.delete(model)
        try context.save()
    }

    func setPinned(id: UUID, isPinned: Bool) throws {
        guard let model = allAnniversaries().first(where: { $0.id == id }) else { return }
        model.isPinned = isPinned
        model.updatedAt = .now
        try context.save()
    }

    func setWidgetVisibility(id: UUID, isVisible: Bool) throws {
        guard let model = allAnniversaries().first(where: { $0.id == id }) else { return }
        model.isVisibleInWidget = isVisible
        model.updatedAt = .now
        try context.save()
    }

    func categories() -> [CategoryModel] {
        allCategories().sorted { ($0.sortOrder, $0.displayName()) < ($1.sortOrder, $1.displayName()) }
    }

    func tags() -> [TagModel] {
        allTags().sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    @discardableResult
    func saveCategory(
        id: UUID? = nil,
        name: String,
        symbolName: String,
        colorToken: String
    ) throws -> CategoryModel {
        let normalized = normalizedName(name)
        guard !normalized.isEmpty else { throw AnniversaryValidationError.emptyTitle }
        let model =
            id.flatMap { target in allCategories().first(where: { $0.id == target }) }
            ?? allCategories().first(where: { normalizedName($0.name) == normalized })
            ?? CategoryModel(name: normalized)
        if model.modelContext == nil { context.insert(model) }
        model.name = normalized
        model.symbolName = symbolName
        model.colorToken = colorToken
        try context.save()
        return model
    }

    func deleteCategory(id: UUID) throws {
        guard let model = allCategories().first(where: { $0.id == id }) else { return }
        context.delete(model)
        try context.save()
    }

    @discardableResult
    func saveTag(id: UUID? = nil, name: String) throws -> TagModel {
        let normalized = normalizedName(name)
        guard !normalized.isEmpty else { throw AnniversaryValidationError.emptyTitle }
        let model =
            id.flatMap { target in allTags().first(where: { $0.id == target }) }
            ?? allTags().first(where: { normalizedName($0.name) == normalized })
            ?? TagModel(name: normalized)
        if model.modelContext == nil { context.insert(model) }
        model.name = normalized
        try context.save()
        return model
    }

    func deleteTag(id: UUID) throws {
        guard let model = allTags().first(where: { $0.id == id }) else { return }
        context.delete(model)
        try context.save()
    }

    private func allAnniversaries() -> [AnniversaryModel] {
        (try? context.fetch(FetchDescriptor<AnniversaryModel>())) ?? []
    }

    private func allCategories() -> [CategoryModel] {
        (try? context.fetch(FetchDescriptor<CategoryModel>())) ?? []
    }

    private func allTags() -> [TagModel] {
        (try? context.fetch(FetchDescriptor<TagModel>())) ?? []
    }

    private func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func map(_ model: AnniversaryModel) -> AnniversaryRecord {
        AnniversaryRecord(
            id: model.id,
            title: model.title,
            notes: model.notes,
            calendarKind: CalendarKind(rawValue: model.calendarKindRaw) ?? .gregorian,
            date: AnniversaryDate(
                year: model.year,
                month: model.month,
                day: model.day,
                hour: model.hour,
                minute: model.minute,
                isLeapMonth: model.isLeapMonth
            ),
            isAllDay: model.isAllDay,
            recurrence: RecurrenceRule(
                unit: model.recurrenceUnitRaw.flatMap(RecurrenceRule.Unit.init(rawValue:)),
                interval: model.recurrenceInterval
            ),
            displayMode: DisplayMode(rawValue: model.displayModeRaw) ?? .countdown,
            reminders: (model.reminders ?? []).map {
                ReminderSpec(
                    id: $0.id,
                    offsetMinutes: $0.offsetMinutes,
                    timeOfDayMinutes: $0.timeOfDayMinutes,
                    isEnabled: $0.isEnabled
                )
            },
            category: model.category.map {
                CategoryReference(
                    id: $0.id,
                    name: $0.displayName(),
                    symbolName: $0.symbolName,
                    colorToken: $0.colorToken
                )
            },
            tags: (model.tags ?? []).map { TagReference(id: $0.id, name: $0.name) },
            isPinned: model.isPinned,
            isVisibleInWidget: model.isVisibleInWidget,
            calendarEventIdentifier: model.calendarEventIdentifier
        )
    }
}
