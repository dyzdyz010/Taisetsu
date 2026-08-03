import LifeTimerCore
import SwiftUI

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
    @Binding var draft: AnniversaryDraft

    var body: some View {
        Section("重复与显示") {
            Toggle("重复", isOn: recurrenceEnabledBinding)
                .accessibilityIdentifier("recurrence-enabled")

            if draft.recurrenceUnit != nil {
                HStack(spacing: 10) {
                    Text("每")
                    Text(draft.recurrenceInterval, format: .number)
                        .monospacedDigit()
                        .frame(minWidth: 24, alignment: .trailing)

                    Picker("单位", selection: recurrenceUnitBinding) {
                        ForEach(RecurrenceRule.Unit.allCases, id: \.self) { unit in
                            Text(unitTitle(unit)).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityLabel("重复单位")
                    .accessibilityIdentifier("recurrence-unit")

                    Spacer(minLength: 8)

                    Stepper("重复数量", value: $draft.recurrenceInterval, in: 1...999)
                        .labelsHidden()
                        .accessibilityLabel("重复数量")
                        .accessibilityValue(
                            "每 \(draft.recurrenceInterval) \(unitTitle(draft.recurrenceUnit ?? .year))"
                        )
                        .accessibilityIdentifier("recurrence-interval")
                }
            }

            Picker("计时方式", selection: $draft.displayMode) {
                Text("倒计时").tag(DisplayMode.countdown)
                Text("正计时").tag(DisplayMode.countUp)
                Text("同时显示").tag(DisplayMode.both)
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

    private func unitTitle(_ unit: RecurrenceRule.Unit) -> String {
        switch unit {
        case .day: "天"
        case .week: "周"
        case .month: "月"
        case .year: "年"
        }
    }
}
