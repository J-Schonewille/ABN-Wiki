import SwiftUI

/// A text field with a visible label above it, and optional helper text or an error below it.
/// - VoiceOver reads it as the field's label.
/// - An error becomes part of that label ("Latitude, Enter a number between −90 and 90"), so VoiceOver reads it
///   whenever the field gets focus. The label still starts with the visible text, so Voice Control users can say
///   what they see.
/// - Don't set an accessibility label on the field yourself; this view does.
public struct DSLabeledField<Field: View>: View {
    private let label: Text
    private let helper: Text?
    private let error: Text?
    private let field: Field

    @FocusState private var isFocused: Bool

    public init(_ label: Text, helper: Text? = nil, error: Text? = nil, @ViewBuilder field: () -> Field) {
        self.label = label
        self.helper = helper
        self.error = error
        self.field = field()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xSmall) {
            label
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DSColor.textPrimary)
                // The field is our main element so disable here so VoiceOver doesn't say it twice.
                .accessibilityHidden(true)
            field
                .dsTextField(isFocused: $isFocused, isInvalid: error != nil)
                .accessibilityLabel(accessibilityLabel)
                // iOS 26.5 ignores this on a TextField, so Voice Control still uses the whole label for now.
                .accessibilityInputLabels([label])
                .accessibilityHint(accessibilityHint)
            if let error {
                Label {
                    error
                } icon: {
                    Image(.fieldError)
                        .accessibilityHidden(true)
                }
                .font(.footnote)
                .foregroundStyle(DSColor.danger)
                .accessibilityHidden(true)
            } else if let helper {
                helper
                    .font(.footnote)
                    .foregroundStyle(DSColor.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilityHint: Text {
        (error == nil ? helper : nil) ?? Text(verbatim: "")
    }

    private var accessibilityLabel: Text {
        if let error {
            Text("\(label), \(error)")  // comma adds pause
        } else {
            label
        }
    }
}

// MARK: - Previews

private struct LabeledFieldPreview: View {
    @State private var latitude = ""
    @State private var longitude = "200"

    var body: some View {
        VStack(spacing: DSSpacing.large) {
            DSLabeledField(
                Text(verbatim: "Latitude"),
                helper: Text(verbatim: "Between −90 and 90, for example 52.3676.")
            ) {
                TextField(
                    text: $latitude,
                    prompt: Text(verbatim: "52.3676").foregroundStyle(DSColor.textSecondary)
                ) {
                    Text(verbatim: "Latitude")
                }
            }
            DSLabeledField(
                Text(verbatim: "Longitude"),
                helper: Text(verbatim: "Between −180 and 180."),
                error: Text(verbatim: "Enter a longitude between −180 and 180.")
            ) {
                TextField(text: $longitude) { Text(verbatim: "Longitude") }
            }
        }
        .padding(DSSpacing.medium)
        .background(DSColor.background)
    }
}

#Preview("Light") {
    LabeledFieldPreview()
}

#Preview("Dark") {
    LabeledFieldPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    LabeledFieldPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
