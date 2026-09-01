import SwiftUI
import Testing

@testable import Taisetsu

struct AdaptiveLayoutTests {
    @Test func regularWidthUsesTwoColumnsOnlyWhenContentCanSupportThem() {
        #expect(
            TaisetsuAdaptiveLayout.contentComposition(
                availableWidth: 919,
                horizontalSizeClass: .regular
            ) == .singleColumn
        )
        #expect(
            TaisetsuAdaptiveLayout.contentComposition(
                availableWidth: 920,
                horizontalSizeClass: .regular
            ) == .twoColumns
        )
    }

    @Test func compactAndUnspecifiedWidthsStaySingleColumn() {
        #expect(
            TaisetsuAdaptiveLayout.contentComposition(
                availableWidth: 1_200,
                horizontalSizeClass: .compact
            ) == .singleColumn
        )
        #expect(
            TaisetsuAdaptiveLayout.contentComposition(
                availableWidth: 1_200,
                horizontalSizeClass: nil
            ) == .singleColumn
        )
    }
}
