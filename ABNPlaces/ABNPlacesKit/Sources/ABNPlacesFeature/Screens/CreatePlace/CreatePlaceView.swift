import ABNDesignSystem
import ABNPlacesUITestContract
import SwiftUI

/// The fields use `.numbersAndPunctuation`, because `.decimalPad` has no minus key.
/// After a save with errors, keyboard and VoiceOver focus move to the first invalid field, which reads its error.
struct CreatePlaceView: View {

    @Bindable var model: CreatePlaceModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @FocusState private var focusedField: CreatePlaceModel.Field?
    @AccessibilityFocusState private var voiceOverField: CreatePlaceModel.Field?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.large) {
                nameField
                latitudeField
                longitudeField
                saveButton
            }
            .padding(DSSpacing.medium)
        }
        .onTapGesture { focusedField = nil }  // A tap outside the fields hides the keyboard.
        .background(DSColor.background)
        .navigationTitle(Text("New place", bundle: #bundle, comment: "Title of the create-place sheet."))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                cancelButton
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier(AccessibilityID.CreatePlace.cancel)
            }
        }
    }

    private func save() {
        switch model.save() {
        case .invalid(let field):
            focusedField = field
            voiceOverField = field
        case .saved:
            announce(
                localized(
                    "Place added to the list",
                    locale: locale,
                    comment: "Announced by VoiceOver when the create-place sheet has added a place."
                )
            )
            dismiss()
        case .alreadySaved:
            announce(
                localized(
                    "Place already in the list",
                    locale: locale,
                    comment: "Announced by VoiceOver when the create-place sheet saves a place that was saved before."
                )
            )
            dismiss()
        }
    }
}

// MARK: - View Builders

private extension CreatePlaceView {

    /// No placeholder: the label already shows, and placeholder gray is only 1.7:1 contrast.
    /// Empty, not nil, because without a prompt SwiftUI repeats the label in the field.
    private static let noPrompt = Text(verbatim: "")

    var nameField: some View {
        DSLabeledField(Text("Name (optional)", bundle: #bundle, comment: "Label of the optional name field.")) {
            TextField(text: $model.name, prompt: Self.noPrompt) {
                Text("Name (optional)", bundle: #bundle, comment: "Label of the optional name field.")
            }
            .textInputAutocapitalization(.words)
            .submitLabel(.next)
            .focused($focusedField, equals: .name)
            .accessibilityFocused($voiceOverField, equals: .name)
            .onSubmit { focusedField = .latitude }
            .accessibilityIdentifier(AccessibilityID.CreatePlace.name)
        }
    }

    var latitudeField: some View {
        DSLabeledField(
            Text("Latitude", bundle: #bundle, comment: "Label of the latitude field."),
            helper: Text(
                "A point or a comma both work, for example 52.3547 or 52,3547.",
                bundle: #bundle,
                comment: "Help under the latitude field."
            ),
            error: model.latitudeError.map { Text($0.latitudeMessage(in: locale)) }
        ) {
            TextField(text: $model.latitude, prompt: Self.noPrompt) {
                Text("Latitude", bundle: #bundle, comment: "Label of the latitude field.")
            }
            .keyboardType(.numbersAndPunctuation)
            .autocorrectionDisabled()
            .submitLabel(.next)
            .focused($focusedField, equals: .latitude)
            .accessibilityFocused($voiceOverField, equals: .latitude)
            .onSubmit { focusedField = .longitude }
            .accessibilityIdentifier(AccessibilityID.CreatePlace.latitude)
        }
    }

    var longitudeField: some View {
        DSLabeledField(
            Text("Longitude", bundle: #bundle, comment: "Label of the longitude field."),
            helper: Text(
                "A point or a comma both work, for example 4.8339 or 4,8339.",
                bundle: #bundle,
                comment: "Help under the longitude field."
            ),
            error: model.longitudeError.map { Text($0.longitudeMessage(in: locale)) }
        ) {
            TextField(text: $model.longitude, prompt: Self.noPrompt) {
                Text("Longitude", bundle: #bundle, comment: "Label of the longitude field.")
            }
            .keyboardType(.numbersAndPunctuation)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($focusedField, equals: .longitude)
            .accessibilityFocused($voiceOverField, equals: .longitude)
            .onSubmit(save)
            .accessibilityIdentifier(AccessibilityID.CreatePlace.longitude)
        }
    }

    /// iOS 26's cancel glyph: VoiceOver and Voice Control call it "Cancel", and it shows in the Large Content Viewer.
    @ViewBuilder var cancelButton: some View {
        if #available(iOS 26, *) {
            Button(role: .cancel) {
                dismiss()
            }
        } else {
            Button {
                dismiss()
            } label: {
                Text("Cancel", bundle: #bundle, comment: "Closes the create-place sheet without saving.")
            }
        }
    }

    var saveButton: some View {
        Button(action: save) {
            Text(
                "Save",
                bundle: #bundle,
                comment: "Primary button of the create-place sheet: adds the place to the list."
            )
        }
        .buttonStyle(.dsPrimary(fullWidth: true))
        .keyboardShortcut(.return, modifiers: .command)
        .accessibilityIdentifier(AccessibilityID.CreatePlace.save)
    }
}

// MARK: - Previews

private struct ErrorsPreview: View {
    @State private var model = CreatePlaceModel()

    var body: some View {
        NavigationStack {
            CreatePlaceView(model: model)
        }
        .onAppear {
            model.latitude = "52,3547"
            model.longitude = "200"
            _ = model.save()
        }
    }
}

#Preview("Empty") {
    CreatePlaceSheet()
}

#Preview("Errors") {
    ErrorsPreview()
}

#Preview("Dark") {
    CreatePlaceSheet()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    CreatePlaceSheet()
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Dutch") {
    CreatePlaceSheet()
        .environment(\.locale, Locale(identifier: "nl_NL"))
}
