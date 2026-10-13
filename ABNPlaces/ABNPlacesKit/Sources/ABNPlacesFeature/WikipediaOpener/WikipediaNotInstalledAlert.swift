import SwiftUI

extension View {
    /// A system alert: VoiceOver reads the title and message, and "OK" is the cancel button, so Esc closes it too.
    func wikipediaNotInstalledAlert(_ opener: WikipediaOpener) -> some View {
        alert(
            Text("Wikipedia isn't installed", bundle: #bundle, comment: "Alert title when opening fails."),
            isPresented: Bindable(opener).showsNotInstalledAlert
        ) {
            Button(role: .cancel) {
            } label: {
                Text("OK", bundle: #bundle, comment: "Alert button that closes the alert.")
            }
        } message: {
            Text(
                "Install the Wikipedia app to see this place on the map.",
                bundle: #bundle,
                comment: "Alert message when the Wikipedia app isn't installed."
            )
        }
    }
}

// MARK: - Previews

/// The alert, shown as soon as the preview appears.
private struct NotInstalledAlertPreview: View {
    @State private var opener = WikipediaOpener()

    var body: some View {
        Color.clear
            .wikipediaNotInstalledAlert(opener)
            .onAppear { opener.showsNotInstalledAlert = true }
    }
}

#Preview("Light") {
    NotInstalledAlertPreview()
}

#Preview("Dark") {
    NotInstalledAlertPreview()
        .preferredColorScheme(.dark)
}

#Preview("Dutch") {
    NotInstalledAlertPreview()
        .environment(\.locale, Locale(identifier: "nl_NL"))
}
