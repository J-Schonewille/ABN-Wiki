import SwiftUI

extension View {
    /// Styles a `TextField` or `SecureField` as a design-system field.
    /// - A border with at least 3:1 contrast, because the border is what shows an empty field is there.
    /// - A 2 pt purple ring while focused, or a 2 pt red border when `isInvalid`.
    public func dsTextField(isFocused: FocusState<Bool>.Binding, isInvalid: Bool = false) -> some View {
        modifier(DSTextFieldModifier(isFocused: isFocused, isInvalid: isInvalid))
    }
}

private struct DSTextFieldModifier: ViewModifier {
    @FocusState.Binding var isFocused: Bool
    let isInvalid: Bool

    @ScaledMetric(relativeTo: .body) private var verticalPadding = DSSpacing.small

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: DSRadius.field)
        content
            .textFieldStyle(.plain)
            .focused($isFocused)
            .font(.body)
            .foregroundStyle(DSColor.textPrimary)
            .tint(DSColor.accent)
            .padding(.horizontal, DSSpacing.small)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: DSSize.minimumTouchTarget)
            .background {
                shape
                    .fill(DSColor.surface)
                    .onTapGesture { isFocused = true }
                    .accessibilityHidden(true)
            }
            .overlay {
                shape
                    .strokeBorder(borderColor, lineWidth: isInvalid || isFocused ? 2 : 1)
                    .allowsHitTesting(false)
            }
    }

    private var borderColor: DSColor {
        if isInvalid { return DSColor.danger }
        return isFocused ? DSColor.accent : DSColor.fieldBorder
    }
}

// MARK: - Previews

private struct TextFieldPreview: View {
    @State private var text = ""
    @State private var invalidText = "100"
    @FocusState private var isFocused: Bool
    @FocusState private var isInvalidFocused: Bool

    var body: some View {
        VStack(spacing: DSSpacing.medium) {
            TextField(
                text: $text,
                prompt: Text(verbatim: "52.3676").foregroundStyle(DSColor.textSecondary)
            ) {
                Text(verbatim: "Latitude")
            }
            .dsTextField(isFocused: $isFocused)
            TextField(text: $invalidText) { Text(verbatim: "Latitude") }
                .dsTextField(isFocused: $isInvalidFocused, isInvalid: true)
        }
        .padding(DSSpacing.medium)
        .background(DSColor.background)
    }
}

#Preview("Light") {
    TextFieldPreview()
}

#Preview("Dark") {
    TextFieldPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    TextFieldPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
