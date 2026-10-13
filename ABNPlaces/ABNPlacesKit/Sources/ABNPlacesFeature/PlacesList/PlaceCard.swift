import ABNDesignSystem
import ABNPlacesCore
import SwiftUI

/// A place as a card that opens it in Wikipedia: its name, or "Unnamed place", and its coordinates.
/// VoiceOver reads one button, "Amsterdam, 52.35 degrees north, 4.83 degrees east", with the hint "Opens in
/// Wikipedia". Voice Control users only say the name: "Tap Amsterdam".
struct PlaceCard: View {
    static let trailingSymbol = DSSymbol.openInOtherApp

    let place: Place
    let action: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        let formatter = CoordinateFormatter(locale: locale)
        Button(action: action) {
            DSCard(
                symbol: .mapPin,
                title: title,
                subtitle: Text(formatter.text(for: place.coordinate)),
                trailingSymbol: Self.trailingSymbol
            )
        }
        .buttonStyle(.dsCard)
        // The coordinates in words: VoiceOver would read "52.3547° N" as "degrees N". On the Button, because a longer
        // label on the subtitle made the accessibility audit report its text as cut off.
        .accessibilityLabel(
            Text(
                "\(title), \(formatter.spokenText(for: place.coordinate))",
                bundle: #bundle,
                comment: "A label in two parts, already written out: latitude and longitude, or name and coordinates."
            )
        )
        .accessibilityHint(Text("Opens in Wikipedia", bundle: #bundle, comment: "VoiceOver hint of a place card."))
        // Nobody wants to say the coordinates out loud.
        .accessibilityInputLabels([title])
    }

    private var title: Text {
        if let name = place.name {
            Text(name)  // Data, never translated.
        } else {
            Text("Unnamed place", bundle: #bundle, comment: "Card title for a place without a name.")
        }
    }
}

// MARK: - Previews

// DEBUG only: the previews use the fixtures, which Release builds don't have.
#if DEBUG
/// A named place, and one without a name.
private struct PlaceCardPreview: View {
    var body: some View {
        VStack(spacing: DSSpacing.small) {
            PlaceCard(place: .amsterdam) {}
            PlaceCard(place: .unnamedMadrid) {}
        }
        .padding(DSSpacing.medium)
        .background(DSColor.background)
    }
}

#Preview("Light") {
    PlaceCardPreview()
}

#Preview("Dark") {
    PlaceCardPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    PlaceCardPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Dutch") {
    PlaceCardPreview()
        .environment(\.locale, Locale(identifier: "nl_NL"))
}
#endif
