import Foundation
import Observation
import TaisetsuCore

@MainActor
@Observable
final class AnniversaryEditorViewModel {
    let repository: AnniversaryRepository
    var draft: AnniversaryDraft
    var errorMessage: String?

    init(repository: AnniversaryRepository, draft: AnniversaryDraft = .new()) {
        self.repository = repository
        self.draft = draft
    }

    func save() -> Bool {
        do {
            try repository.save(draft: draft)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func addReminder(offsetMinutes: Int, timeOfDayMinutes: Int? = nil) {
        guard
            !draft.reminders.contains {
                $0.offsetMinutes == offsetMinutes && $0.timeOfDayMinutes == timeOfDayMinutes
            }
        else { return }
        draft.reminders.append(
            ReminderSpec(offsetMinutes: offsetMinutes, timeOfDayMinutes: timeOfDayMinutes)
        )
        draft.reminders.sort { $0.offsetMinutes < $1.offsetMinutes }
    }

    func removeReminders(at offsets: IndexSet) {
        draft.reminders.remove(atOffsets: offsets)
    }
}
