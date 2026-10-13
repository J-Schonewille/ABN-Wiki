import ABNDesignSystem
import ABNPlacesCore
import SwiftUI
import Testing

@testable import ABNPlacesFeature

@MainActor
@Suite("PlaceCard snapshots")
struct PlaceCardTests {
    @Test("Place cards, for VoiceOver: one button each, with the name, the coordinates in words and the hint")
    func placeCardsAccessibility() {
        let cards = VStack(spacing: DSSpacing.small) {
            PlaceCard(place: .amsterdam) {}
            PlaceCard(place: .unnamedMadrid) {}
        }

        assertComponentAccessibilitySnapshot(of: cards, named: "place-cards")
    }
}
