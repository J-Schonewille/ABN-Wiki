import ABNDesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("DSButtonStyle snapshots")
struct DSButtonStyleTests {
    @Test("Buttons", arguments: ComponentVariant.allCases)
    func buttons(_ variant: ComponentVariant) {
        assertComponentSnapshot(of: ButtonsFixture(), as: variant, named: "buttons")
    }

    @Test("Buttons, for VoiceOver: each is one button, the disabled one dimmed")
    func buttonsAccessibility() {
        assertComponentAccessibilitySnapshot(of: ButtonsFixture(), named: "buttons")
    }
}

// MARK: - Fixtures

private struct ButtonsFixture: View {
    var body: some View {
        VStack(spacing: DSSpacing.medium) {
            Button {
            } label: {
                Label {
                    Text(verbatim: "Add custom location")
                } icon: {
                    Image(.add)
                }
            }
            .buttonStyle(.dsPrimary(fullWidth: true))
            Button {
            } label: {
                Text(verbatim: "Open")
            }
            .buttonStyle(.dsPrimary)
            Button {
            } label: {
                Text(verbatim: "Try again")
            }
            .buttonStyle(.dsSecondary)
            Button {
            } label: {
                Text(verbatim: "Unavailable")
            }
            .buttonStyle(.dsPrimary)
            .disabled(true)
        }
    }
}
