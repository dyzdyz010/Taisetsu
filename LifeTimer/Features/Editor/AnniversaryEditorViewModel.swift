import Foundation
import LifeTimerCore
import Observation

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

    func addReminder(offsetMinutes: Int) {
        guard !draft.reminders.contains(where: { $0.offsetMinutes == offsetMinutes }) else { return }
        draft.reminders.append(ReminderSpec(offsetMinutes: offsetMinutes))
        draft.reminders.sort { $0.offsetMinutes < $1.offsetMinutes }
    }

    func removeReminders(at offsets: IndexSet) {
        draft.reminders.remove(atOffsets: offsets)
    }
}
