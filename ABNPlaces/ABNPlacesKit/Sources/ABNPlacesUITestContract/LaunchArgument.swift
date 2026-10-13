#if DEBUG
/// Read by DEBUG builds, passed by the UI tests. Shared, so a typo breaks the build instead of loading the live feed.
public enum LaunchArgument {
    /// `-PlacesScenario <scenario>`: a canned feed instead of the network.
    public static let scenario = "PlacesScenario"
    /// `-PlacesAnimationsDisabled YES` turns UIKit's animations off.
    public static let animationsDisabled = "PlacesAnimationsDisabled"

    public enum Scenario: String, CaseIterable, Sendable {
        /// The feed's four places.
        case success
        case empty
        /// Every load fails as offline.
        case offline
        /// Loading never ends, so the placeholders stay.
        case slow
        /// Offline first. Every later load takes two seconds, then brings the four places.
        case recovers
        /// The four places first. Every later load takes two seconds, then brings Amsterdam only.
        case updates
    }
}
#endif
