import ABNDesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("DSBanner snapshots")
struct DSBannerTests {
    @Test("Banner", arguments: ComponentVariant.allCases)
    func banner(_ variant: ComponentVariant) {
        assertComponentSnapshot(of: BannerFixture(), as: variant, named: "banner")
    }

    @Test(
        "Banner, for VoiceOver: the message, then its action, which moves below it at AX5",
        arguments: [ComponentVariant.light, .lightAX5]
    )
    func bannerAccessibility(_ variant: ComponentVariant) {
        assertComponentAccessibilitySnapshot(of: BannerFixture(), as: variant, named: "banner")
    }
}

// MARK: - Fixtures

private struct BannerFixture: View {
    var body: some View {
        DSBanner(Text(verbatim: "Couldn't refresh. Showing earlier results.")) {
            Button {
            } label: {
                Text(verbatim: "Retry")
            }
        }
    }
}
