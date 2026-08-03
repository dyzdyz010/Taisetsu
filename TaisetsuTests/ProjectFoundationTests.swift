import Testing

@testable import TaisetsuCore

struct ProjectFoundationTests {
    @Test func technicalIdentifiersUseTaisetsu() {
        #expect(AppConfiguration.appGroupIdentifier == "group.com.dyz.Taisetsu")
        #expect(AppConfiguration.cloudContainerIdentifier == "iCloud.com.dyz.Taisetsu")
        #expect(AppConfiguration.widgetKind == "TaisetsuUpcoming")
    }
}
