import ABNDesignSystem
import SwiftUI

/// The first load failed: what happened, what to do about it, and Retry.
/// VoiceOver reads the title as a heading, then the message, then Retry. The screen announces the failure itself,
/// once, when it happens.
struct LoadFailureView: View {
    let failure: LoadFailure
    let retry: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        DSStateView(
            symbol: failure.symbol,
            title: Text(failure.title(in: locale)),
            message: Text(failure.message(in: locale))
        ) {
            Button(action: retry) {
                Text("Retry", bundle: #bundle, comment: "Button that tries to load the places again.")
            }
        }
    }
}

// MARK: - Previews

private struct LoadFailurePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.medium) {
                LoadFailureView(failure: .offline) {}
                LoadFailureView(failure: .server) {}
                LoadFailureView(failure: .unexpectedData) {}
            }
            .padding(DSSpacing.medium)
        }
        .background(DSColor.background)
    }
}

#Preview("Light") {
    LoadFailurePreview()
}

#Preview("Dark") {
    LoadFailurePreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    LoadFailurePreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Dutch") {
    LoadFailurePreview()
        .environment(\.locale, Locale(identifier: "nl_NL"))
}
