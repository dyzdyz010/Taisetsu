import SwiftUI

enum TaisetsuAdaptiveLayout {
    enum ContentComposition: Equatable {
        case singleColumn
        case twoColumns
    }

    static let dashboardMaxWidth: CGFloat = 1_040
    static let formMaxWidth: CGFloat = 760
    static let editorMaxWidth: CGFloat = 760
    static let wideContentThreshold: CGFloat = 920
    static let columnSpacing: CGFloat = 28

    static func contentComposition(
        availableWidth: CGFloat,
        horizontalSizeClass: UserInterfaceSizeClass?
    ) -> ContentComposition {
        guard horizontalSizeClass == .regular, availableWidth >= wideContentThreshold else {
            return .singleColumn
        }
        return .twoColumns
    }

    static func horizontalPadding(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 24 : 16
    }
}

extension View {
    func taisetsuReadableForm(maxWidth: CGFloat = TaisetsuAdaptiveLayout.formMaxWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}
