import ABNDesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("DSLabeledField snapshots")
struct DSLabeledFieldTests {
    @Test("Labeled field", arguments: ComponentVariant.allCases)
    func labeledField(_ variant: ComponentVariant) {
        assertComponentSnapshot(of: LabeledFieldFixture(isInvalid: false), as: variant, named: "labeled-field")
    }

    @Test("Labeled field with an error", arguments: ComponentVariant.allCases)
    func labeledFieldWithError(_ variant: ComponentVariant) {
        assertComponentSnapshot(of: LabeledFieldFixture(isInvalid: true), as: variant, named: "labeled-field-error")
    }

    /// The visible label and helper add no elements. The snapshot always shows "Double tap to edit." as a text field's
    /// hint, instead of the helper.
    @Test("Labeled field, for VoiceOver: one text field, read by its label")
    func labeledFieldAccessibility() {
        assertComponentAccessibilitySnapshot(of: LabeledFieldFixture(isInvalid: false), named: "labeled-field")
    }

    /// VoiceOver reads the error with the field: "Longitude, Enter a longitude between −180 and 180.", value 200.
    @Test("Labeled field with an error, for VoiceOver: the error is part of the field's label")
    func labeledFieldWithErrorAccessibility() {
        assertComponentAccessibilitySnapshot(of: LabeledFieldFixture(isInvalid: true), named: "labeled-field-error")
    }
}

// MARK: - Fixtures

private struct LabeledFieldFixture: View {
    let isInvalid: Bool

    var body: some View {
        if isInvalid {
            DSLabeledField(
                Text(verbatim: "Longitude"),
                helper: Text(verbatim: "Between −180 and 180."),
                error: Text(verbatim: "Enter a longitude between −180 and 180.")
            ) {
                TextField(text: .constant("200")) { Text(verbatim: "Longitude") }
            }
        } else {
            DSLabeledField(
                Text(verbatim: "Latitude"),
                helper: Text(verbatim: "Between −90 and 90. Use a dot or a comma for decimals.")
            ) {
                TextField(
                    text: .constant(""),
                    prompt: Text(verbatim: "52.3676").foregroundStyle(DSColor.textSecondary)
                ) {
                    Text(verbatim: "Latitude")
                }
            }
        }
    }
}
