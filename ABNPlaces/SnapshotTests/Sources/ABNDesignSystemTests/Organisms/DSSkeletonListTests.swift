import ABNDesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("DSSkeletonList snapshots")
struct DSSkeletonListTests {
    @Test("Skeleton list", arguments: ComponentVariant.allCases)
    func skeleton(_ variant: ComponentVariant) {
        assertComponentSnapshot(of: SkeletonFixture(), as: variant, named: "skeleton")
    }

    @Test("Skeleton list, for VoiceOver: one element, \"Loading places\"")
    func skeletonAccessibility() {
        assertComponentAccessibilitySnapshot(of: SkeletonFixture(), named: "skeleton")
    }
}

// MARK: - Fixtures

private struct SkeletonFixture: View {
    var body: some View {
        DSSkeletonList(count: 3, accessibilityLabel: Text(verbatim: "Loading places"))
    }
}
