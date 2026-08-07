import Foundation
import TaisetsuCore
import Testing

struct CalendarSyncBackoffTests {
    private let origin = Date(timeIntervalSince1970: 1_000_000)

    @Test func firstPromptIsImmediatelyEligibleAndAdvancesExponentially() {
        var state = CalendarSyncBackoff()
        #expect(state.isEligible(at: origin))

        state.recordDeferral(at: origin)
        #expect(state.nextEligibleDate == origin.addingTimeInterval(86_400))
        #expect(!state.isEligible(at: origin.addingTimeInterval(86_399)))
        #expect(state.isEligible(at: origin.addingTimeInterval(86_400)))

        state.recordDeferral(at: origin.addingTimeInterval(86_400))
        #expect(state.nextEligibleDate == origin.addingTimeInterval(86_400 * 3))
    }

    @Test func deferralsCapAtNinetyDayIntervals() {
        var state = CalendarSyncBackoff()
        for day in [0, 1, 3, 7, 15, 31, 63, 127] {
            state.recordDeferral(at: origin.addingTimeInterval(TimeInterval(day) * 86_400))
        }
        #expect(state.nextEligibleDate == origin.addingTimeInterval(TimeInterval(127 + 90) * 86_400))
    }

    @Test func neverRemindDisablesEligibilityPermanently() {
        var state = CalendarSyncBackoff()
        state.neverRemind()
        #expect(!state.isEligible(at: origin))
        #expect(state.isNeverRemind)
    }
}
