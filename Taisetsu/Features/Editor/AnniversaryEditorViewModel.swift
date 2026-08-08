import Foundation
import Observation
import TaisetsuCore

@MainActor
@Observable
final class AnniversaryEditorViewModel {
    private let repository: AnniversaryRepository

    var draft: AnniversaryDraft
    var errorMessage: String?
    private(set) var savedRecord: AnniversaryRecord?

    var categories: [CategoryModel] { repository.categories() }
    var tags: [TagModel] { repository.tags() }

    init(repository: AnniversaryRepository, record: AnniversaryRecord? = nil) {
        self.repository = repository
        draft = record.map(AnniversaryDraft.init(record:)) ?? AnniversaryDraft()
    }

    @discardableResult
    func save() -> Bool {
        do {
            savedRecord = try repository.save(draft: draft)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func addReminder(offsetMinutes: Int, timeOfDayMinutes: Int? = nil) {
        let isDuplicate = draft.reminders.contains {
            $0.offsetMinutes == offsetMinutes && $0.timeOfDayMinutes == timeOfDayMinutes
        }
        guard !isDuplicate else { return }
        draft.reminders.append(
            ReminderSpec(offsetMinutes: offsetMinutes, timeOfDayMinutes: timeOfDayMinutes)
        )
        draft.reminders.sort { $0.offsetMinutes < $1.offsetMinutes }
    }

    func removeReminders(at offsets: IndexSet) {
        draft.reminders.remove(atOffsets: offsets)
    }
}
