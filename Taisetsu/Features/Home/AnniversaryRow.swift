import SwiftUI
import TaisetsuCore

struct AnniversaryRow: View {
    @Environment(\.locale) private var locale
    let presentation: AnniversaryPresentation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: presentation.record.category?.symbolName ?? "calendar")
                .foregroundStyle(CategoryStyle.color(for: presentation.record.category?.colorToken ?? "blue"))
                .frame(width: 32, height: 32)
                .background(.quaternary, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(presentation.record.title)
                        .font(.body.weight(.medium))
                    if presentation.record.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(
                    AnniversaryFormatters.relative(
                        presentation.occurrence,
                        mode: presentation.record.displayMode,
                        locale: locale
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if let next = presentation.occurrence.next {
                Text(next, format: .dateTime.month().day())
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
