import ABNDesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("DSStateView snapshots")
struct DSStateViewTests {
    @Test("State view", arguments: ComponentVariant.allCases)
    func stateView(_ variant: ComponentVariant) {
        assertComponentSnapshot(of: StateViewFixture(), as: variant, named: "state-view")
    }

    @Test("State view, for VoiceOver: a heading, the message, then the action")
    func stateViewAccessibility() {
        assertComponentAccessibilitySnapshot(of: StateViewFixture(), named: "state-view")
    }
}

// MARK: - Fixtures

private struct StateViewFixture: View {
    var body: some View {
        DSStateView(
            symbol: .offline,
            title: Text(verbatim: "Couldn't load places"),
            message: Text(verbatim: "Check your connection and try again. You can still add a custom location.")
        ) {
            Button {
            } label: {
                Text(verbatim: "Try again")
            }
        }
    }
}
