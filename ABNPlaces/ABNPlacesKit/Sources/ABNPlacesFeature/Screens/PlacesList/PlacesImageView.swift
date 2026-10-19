import ABNDesignSystem
import ABNPlacesCore
import SwiftUI

/// Loads a place's image and shows it as a ``PlaceThumbnail``. The image fades in.
struct PlacesImageView: View {
    let imageURL: URL?

    /// A fade, not a movement, so it suits Reduce Motion too.
    private static let fade = Animation.easeInOut(duration: 0.25)

    var body: some View {
        AsyncImage(url: imageURL, transaction: Transaction(animation: Self.fade)) { phase in
            PlaceThumbnail(image: phase.image)
        }
    }
}

/// The map pin tile, with the image over it when there is one, in the tile's size and shape.
/// Separate from the loading, so snapshots can show an image without waiting for it.
struct PlaceThumbnail: View {
    let image: Image?

    var body: some View {
        // The tile sets the size, so the image grows with the text like the tile does.
        DSIconTile(symbol: .mapPin)
            .overlay {
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
            }
            .clipShape(DSTileShape())
            // The card reads its title and subtitle; the image adds nothing.
            .accessibilityHidden(true)
    }
}

// MARK: - Previews
#if DEBUG
#Preview("Image") {
    PlacesImageView(imageURL: .placeStubImage)
}

#Preview("No image") {
    PlacesImageView(imageURL: nil)
}

#Preview("AX5") {
    PlacesImageView(imageURL: .placeStubImage)
        .environment(\.dynamicTypeSize, .accessibility5)
}
#endif
