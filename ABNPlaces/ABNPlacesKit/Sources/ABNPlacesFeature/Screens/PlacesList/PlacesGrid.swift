import ABNDesignSystem
import ABNPlacesCore
import SwiftUI

/// The grid for the cards and for their placeholders, so loading looks like what comes next.
/// A column is at least `minimumColumnWidth` wide, and that width grows with the text. That one rule gives one
/// column on an iPhone in portrait, two or three on an iPad, and fewer as the text grows, down to one at the
/// accessibility sizes. No device, size class or orientation checks: the grid only looks at the width it gets.
struct PlacesGrid<Content: View>: View {
    private let content: Content

    /// The narrowest card that still reads well next to another. Two columns need 692 pt, more than any iPhone has
    /// in portrait.
    @ScaledMetric(relativeTo: .body) private var minimumColumnWidth = 340.0

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumColumnWidth), spacing: DSSpacing.small, alignment: .top)],
            spacing: DSSpacing.small
        ) {
            content
        }
    }
}

// MARK: - Previews
#if DEBUG
/// The feed's places in the grid. The number of columns only depends on the width and the text size.
private struct PlacesGridPreview: View {
    var body: some View {
        ScrollView {
            PlacesGrid {
                ForEach([Place].preview) { place in
                    PlaceCard(place: place, imageURL: place.name == nil ? nil : .placeStubImage) {}
                }
            }
            .padding(DSSpacing.medium)
        }
        .background(DSColor.background)
    }
}

#Preview("One column") {
    PlacesGridPreview()
}

#Preview("Two columns", traits: .fixedLayout(width: 1024, height: 500)) {
    PlacesGridPreview()
}

#Preview("Three columns", traits: .fixedLayout(width: 1366, height: 500)) {
    PlacesGridPreview()
}

#Preview("AX5 on a wide screen", traits: .fixedLayout(width: 1366, height: 1000)) {
    PlacesGridPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
#endif
