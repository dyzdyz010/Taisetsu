import Testing

@testable import LifeTimerCore

struct ProjectFoundationTests {
    @Test func appGroupIdentifierIsStable() {
        #expect(AppConfiguration.appGroupIdentifier == "group.com.dyz.LifeTimer")
    }
}
