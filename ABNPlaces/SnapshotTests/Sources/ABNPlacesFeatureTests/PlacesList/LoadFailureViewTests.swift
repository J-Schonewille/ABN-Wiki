import Testing

@testable import ABNPlacesFeature

@MainActor
@Suite("LoadFailureView snapshots")
struct LoadFailureViewTests {
    @Test(
        "The first load's error on its own, for VoiceOver: a heading, the message, then Retry",
        arguments: [ComponentVariant.light, .lightAX5]
    )
    func loadFailureAccessibility(_ variant: ComponentVariant) {
        let failure = LoadFailureView(failure: .offline) {}

        assertComponentAccessibilitySnapshot(of: failure, as: variant, named: "load-failure")
    }
}
