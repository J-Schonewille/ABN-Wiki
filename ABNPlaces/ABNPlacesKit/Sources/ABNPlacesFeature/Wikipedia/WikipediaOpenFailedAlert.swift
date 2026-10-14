import SwiftUI

extension View {
    /// A system alert: VoiceOver reads the title and message, and "OK" is the cancel button, so Esc closes it too.
    func wikipediaOpenFailedAlert(_ opener: WikipediaOpener) -> some View {
        alert(
            Text("Couldn't open Wikipedia", bundle: #bundle, comment: "Alert title when opening Wikipedia fails."),
            isPresented: Bindable(opener).showsOpenFailedAlert
        ) {
            Button(role: .cancel) {
            } label: {
                Text("OK", bundle: #bundle, comment: "Alert button that closes the alert.")
            }
        } message: {
            Text(
                "Check that the Wikipedia app is installed, and allow this app to open it.",
                bundle: #bundle,
                comment: "Alert message when Wikipedia didn't open: not installed, or iOS's prompt was cancelled."
            )
        }
    }
}

// MARK: - Previews

/// The alert, shown as soon as the preview appears.
private struct OpenFailedAlertPreview: View {
    @State private var opener = WikipediaOpener()

    var body: some View {
        Color.clear
            .wikipediaOpenFailedAlert(opener)
            .onAppear { opener.showsOpenFailedAlert = true }
    }
}

#Preview("Light") {
    OpenFailedAlertPreview()
}

#Preview("Dark") {
    OpenFailedAlertPreview()
        .preferredColorScheme(.dark)
}

#Preview("Dutch") {
    OpenFailedAlertPreview()
        .environment(\.locale, Locale(identifier: "nl_NL"))
}
