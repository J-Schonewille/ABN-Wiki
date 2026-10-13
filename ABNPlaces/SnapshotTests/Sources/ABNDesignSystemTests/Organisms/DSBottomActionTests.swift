import ABNDesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("DSBottomAction snapshots")
struct DSBottomActionTests {
    @Test("Bottom action, for VoiceOver: one button, after the content")
    func bottomActionAccessibility() {
        assertComponentAccessibilitySnapshot(of: BottomActionFixture(), named: "bottom-action")
    }
}

// MARK: - Fixtures

/// A card above the pinned bar, in a fixed height so the bar sits below the content.
private struct BottomActionFixture: View {
    var body: some View {
        VStack(spacing: DSSpacing.small) {
            CardButton(
                title: "Amsterdam",
                coordinates: "52.3676° N, 4.9041° E",
                spokenCoordinates: "52.37 degrees north, 4.90 degrees east"
            )
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(height: 260)
        .dsBottomAction {
            Button {
            } label: {
                Label {
                    Text(verbatim: "Add custom location")
                } icon: {
                    Image(.add)
                }
            }
        }
    }
}
