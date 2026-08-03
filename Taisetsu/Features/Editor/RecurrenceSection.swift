import SwiftUI
import TaisetsuCore

enum RecurrenceEditorSelection {
    static func setEnabled(_ isEnabled: Bool, draft: inout AnniversaryDraft) {
        if isEnabled {
            if draft.recurrenceUnit == nil {
                draft.recurrenceUnit = .year
                draft.recurrenceInterval = 1
            }
        } else {
            draft.recurrenceUnit = nil
            draft.recurrenceInterval = 1
        }
    }
}

struct RecurrenceSection: View {
    @Environment(\.locale) private var locale
    @Binding var draft: AnniversaryDraft

    var body: some View {
        Section("Repeat & Count") {
            Toggle("Repeat", isOn: recurrenceEnabledBinding)
                .accessibilityIdentifier("recurrence-enabled")

            if draft.recurrenceUnit != nil {
                HStack(spacing: 10) {
                    Text("Every")
                    Text(draft.recurrenceInterval, format: .number)
                        .monospacedDigit()
                        .frame(minWidth: 24, alignment: .trailing)

                    Picker("Unit", selection: recurrenceUnitBinding) {
                        ForEach(RecurrenceRule.Unit.allCases, id: \.self) { unit in
                            Text(unitTitle(unit, count: draft.recurrenceInterval)).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityLabel("Repeat Unit")
                    .accessibilityIdentifier("recurrence-unit")

                    Spacer(minLength: 8)

                    Stepper("Repeat Quantity", value: $draft.recurrenceInterval, in: 1...999)
                        .labelsHidden()
                        .accessibilityLabel("Repeat Quantity")
                        .accessibilityValue(
                            AnniversaryFormatters.recurrence(
                                RecurrenceRule(
                                    unit: draft.recurrenceUnit,
                                    interval: draft.recurrenceInterval
                                ),
                                locale: locale
                            )
                        )
                        .accessibilityIdentifier("recurrence-interval")
                }
            }

            Picker("Count Style", selection: $draft.displayMode) {
                Text("Countdown").tag(DisplayMode.countdown)
                Text("Count Up").tag(DisplayMode.countUp)
                Text("Show Both").tag(DisplayMode.both)
            }
        }
    }

    private var recurrenceEnabledBinding: Binding<Bool> {
        Binding(
            get: { draft.recurrenceUnit != nil },
            set: {
                var updatedDraft = draft
                RecurrenceEditorSelection.setEnabled($0, draft: &updatedDraft)
                draft = updatedDraft
            }
        )
    }

    private var recurrenceUnitBinding: Binding<RecurrenceRule.Unit> {
        Binding(
            get: { draft.recurrenceUnit ?? .year },
            set: { draft.recurrenceUnit = $0 }
        )
    }

    private func unitTitle(_ unit: RecurrenceRule.Unit, count: Int) -> String {
        let singular = count == 1
        return switch unit {
        case .day: AppLocalization.string(singular ? "Day" : "Days", locale: locale)
        case .week: AppLocalization.string(singular ? "Week" : "Weeks", locale: locale)
        case .month: AppLocalization.string(singular ? "Month" : "Months", locale: locale)
        case .year: AppLocalization.string(singular ? "Year" : "Years", locale: locale)
        }
    }
}
