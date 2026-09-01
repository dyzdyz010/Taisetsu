#if DEBUG
    import Foundation
    import TaisetsuCore

    @MainActor
    enum AppStoreScreenshotData {
        private static let familyCategoryID = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
        private static let loveCategoryID = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
        private static let birthdayCategoryID = UUID(uuidString: "00000000-0000-4000-8000-000000000003")!
        private static let workCategoryID = UUID(uuidString: "00000000-0000-4000-8000-000000000005")!

        static func initialSection(in arguments: [String]) -> String? {
            guard let flagIndex = arguments.firstIndex(of: "-app-store-section") else { return nil }
            let valueIndex = arguments.index(after: flagIndex)
            guard arguments.indices.contains(valueIndex) else { return nil }
            return arguments[valueIndex]
        }

        static func seed(repository: AnniversaryRepository) throws {
            guard repository.fetch().isEmpty else { return }

            let belovedTag = try repository.saveTag(name: "挚爱")
            let familyTag = try repository.saveTag(name: "家人")
            let journeyTag = try repository.saveTag(name: "旅程")

            try repository.save(
                draft: draft(
                    title: "我们的纪念日",
                    notes: "把平凡的一天，过成值得记住的一天。",
                    date: AnniversaryDate(year: 2026, month: 9, day: 18),
                    recurrenceUnit: .year,
                    displayMode: .both,
                    reminders: [
                        ReminderSpec(offsetMinutes: -7 * 24 * 60),
                        ReminderSpec(offsetMinutes: -24 * 60),
                    ],
                    categoryID: loveCategoryID,
                    tagIDs: [belovedTag.id],
                    isPinned: true
                )
            )
            try repository.save(
                draft: draft(
                    title: "下一次旅行",
                    notes: "去看秋天的海，也去收藏新的故事。",
                    date: AnniversaryDate(year: 2026, month: 10, day: 1),
                    reminders: [ReminderSpec(offsetMinutes: -3 * 24 * 60)],
                    categoryID: familyCategoryID,
                    tagIDs: [journeyTag.id]
                )
            )
            try repository.save(
                draft: draft(
                    title: "妈妈的生日",
                    notes: "提前准备一束花和一顿温暖的晚餐。",
                    date: AnniversaryDate(year: 2026, month: 11, day: 6),
                    recurrenceUnit: .year,
                    reminders: [
                        ReminderSpec(offsetMinutes: -7 * 24 * 60),
                        ReminderSpec(offsetMinutes: -24 * 60),
                    ],
                    categoryID: birthdayCategoryID,
                    tagIDs: [familyTag.id]
                )
            )
            try repository.save(
                draft: draft(
                    title: "新年",
                    notes: "愿新的一年，仍有热望，也有从容。",
                    date: AnniversaryDate(year: 2026, month: 1, day: 1),
                    recurrenceUnit: .year,
                    categoryID: familyCategoryID,
                    tagIDs: [familyTag.id]
                )
            )
            try repository.save(
                draft: draft(
                    title: "毕业那天",
                    notes: "从校园出发，去成为自己想成为的人。",
                    date: AnniversaryDate(year: 2024, month: 6, day: 20),
                    displayMode: .countUp,
                    categoryID: workCategoryID,
                    tagIDs: [journeyTag.id]
                )
            )
            try repository.save(
                draft: draft(
                    title: "搬进新家",
                    notes: "灯亮起来的时候，生活也有了新的章节。",
                    date: AnniversaryDate(year: 2025, month: 12, day: 12),
                    displayMode: .countUp,
                    categoryID: familyCategoryID,
                    tagIDs: [familyTag.id]
                )
            )
        }

        private static func draft(
            title: String,
            notes: String,
            date: AnniversaryDate,
            recurrenceUnit: RecurrenceRule.Unit? = nil,
            displayMode: DisplayMode = .countdown,
            reminders: [ReminderSpec] = [],
            categoryID: UUID,
            tagIDs: Set<UUID>,
            isPinned: Bool = false
        ) -> AnniversaryDraft {
            var draft = AnniversaryDraft()
            draft.title = title
            draft.notes = notes
            draft.date = date
            draft.recurrenceUnit = recurrenceUnit
            draft.displayMode = displayMode
            draft.reminders = reminders
            draft.categoryID = categoryID
            draft.tagIDs = tagIDs
            draft.isPinned = isPinned
            draft.isVisibleInWidget = true
            return draft
        }
    }
#endif
