import ABNDesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("DSCard snapshots")
struct DSCardTests {
    @Test("Card", arguments: ComponentVariant.allCases)
    func card(_ variant: ComponentVariant) {
        assertComponentSnapshot(of: CardFixture(), as: variant, named: "card")
    }

    @Test("Card, for VoiceOver: one button per card, with the coordinates in words and the hint")
    func cardAccessibility() {
        assertComponentAccessibilitySnapshot(of: CardFixture(), named: "card")
    }
}

// MARK: - Fixtures

/// Two cards, the second with a title long enough to wrap. The subtitle is read as words ("degrees north").
private struct CardFixture: View {
    var body: some View {
        VStack(spacing: DSSpacing.small) {
            CardButton(
                title: "Amsterdam",
                coordinates: "52.3676° N, 4.9041° E",
                spokenCoordinates: "52.37 degrees north, 4.90 degrees east"
            )
            CardButton(
                title: "Tierra del Fuego National Park, Ushuaia",
                coordinates: "54.8500° S, 68.5667° W",
                spokenCoordinates: "54.85 degrees south, 68.57 degrees west"
            )
        }
    }
}
