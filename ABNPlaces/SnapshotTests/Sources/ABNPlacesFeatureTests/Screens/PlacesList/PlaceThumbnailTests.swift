import ABNDesignSystem
import ABNPlacesCore
import SwiftUI
import Testing
import UIKit

@testable import ABNPlacesFeature

@MainActor
@Suite("PlaceThumbnail snapshots")
struct PlaceThumbnailTests {
    @Test("A place card with an image, and one with the map pin tile", arguments: ComponentVariant.allCases)
    func imageAndTile(_ variant: ComponentVariant) throws {
        let image = try #require(UIImage(contentsOfFile: URL.placeStubImage.path()))

        let cards = VStack(spacing: DSSpacing.small) {
            PlaceCard(place: .amsterdam, image: Image(uiImage: image)) {}
            PlaceCard(place: .unnamedMadrid, image: nil) {}
        }

        assertComponentSnapshot(of: cards, as: variant, named: "place-thumbnails")
    }
}
