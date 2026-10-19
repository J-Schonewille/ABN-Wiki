import ABNDesignSystem
import ABNPlacesCore
import ABNPlacesUITestContract
import SwiftUI

/// A place as a card that opens it in Wikipedia: its name, or "Unnamed place", and its coordinates.
/// VoiceOver reads one button, "Amsterdam, 52.35 degrees north, 4.83 degrees east", with the hint "Opens in
/// Wikipedia". Voice Control users only say the name: "Tap Amsterdam".
struct PlaceCard: View {
    static let trailingSymbol = DSSymbol.openInOtherApp

    let place: Place
    private let image: ImageSource
    let action: () -> Void

    @Environment(\.locale) private var locale

    /// Loads the place's image from `imageURL`. Nil shows the map pin tile.
    init(place: Place, imageURL: URL?, action: @escaping () -> Void) {
        self.place = place
        self.image = .url(imageURL)
        self.action = action
    }

    /// With the image already loaded, so snapshots don't wait for it.
    init(place: Place, image: Image?, action: @escaping () -> Void) {
        self.place = place
        self.image = .loaded(image)
        self.action = action
    }

    var body: some View {
        let formatter = CoordinateFormatter(locale: locale)
        Button(action: action) {
            DSCard(
                thumbnail: thumbnail,
                title: title,
                subtitle: Text(formatter.text(for: place.coordinate)),
                trailingSymbol: Self.trailingSymbol
            )
        }
        .buttonStyle(.dsCard)
        // Coordinates in words: VoiceOver reads "° N" as "degrees N". On the Button, because on the subtitle the audit
        // reports the longer label as cut off.
        .accessibilityLabel(
            Text(
                "\(title), \(formatter.spokenText(for: place.coordinate))",
                bundle: #bundle,
                comment: "A label in two parts, already written out: latitude and longitude, or name and coordinates."
            )
        )
        .accessibilityHint(Text("Opens in Wikipedia", bundle: #bundle, comment: "VoiceOver hint of a place card."))
        // Voice Control users only say the name: "Tap Amsterdam".
        .accessibilityInputLabels([title])
        .accessibilityIdentifier(AccessibilityID.PlacesList.card(id: place.id))
    }

    private var title: Text {
        if let name = place.name {
            Text(name)  // Data, never translated.
        } else {
            Text("Unnamed place", bundle: #bundle, comment: "Card title for a place without a name.")
        }
    }

    @ViewBuilder private var thumbnail: some View {
        switch image {
        case .url(let url):
            PlacesImageView(imageURL: url)
        case .loaded(let image):
            PlaceThumbnail(image: image)
        }
    }

    private enum ImageSource {
        case url(URL?)
        case loaded(Image?)
    }
}

// MARK: - Previews

// DEBUG only: the previews use the fixtures, which Release builds don't have.
#if DEBUG
/// A named place with an image, and one without a name or an image.
private struct PlaceCardPreview: View {
    var body: some View {
        VStack(spacing: DSSpacing.small) {
            PlaceCard(place: .amsterdam, imageURL: .placeStubImage) {}
            PlaceCard(place: .unnamedMadrid, imageURL: nil) {}
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
