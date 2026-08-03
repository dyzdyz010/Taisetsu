import LifeTimerCore
import SwiftUI

struct AnniversaryHeroCard: View {
    let presentation: AnniversaryPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(
                    presentation.record.category?.name ?? "最近纪念日",
                    systemImage: presentation.record.category?.symbolName ?? "calendar"
                )
                .font(.subheadline.weight(.semibold))
                Spacer()
                if presentation.record.isPinned {
                    Image(systemName: "pin.fill")
                        .accessibilityLabel("已置顶")
                }
            }
            Text(presentation.record.title)
                .font(.title2.weight(.bold))
                .lineLimit(2)
            Text(
                AnniversaryFormatters.relative(presentation.occurrence, mode: presentation.record.displayMode)
            )
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .minimumScaleFactor(0.65)
            if let next = presentation.occurrence.next {
                Text(AnniversaryFormatters.date(next, isAllDay: presentation.record.isAllDay))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    CategoryStyle.color(for: presentation.record.category?.colorToken ?? "blue"),
                    CategoryStyle.color(for: presentation.record.category?.colorToken ?? "blue").opacity(
                        0.68),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}
