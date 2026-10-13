import ABNPlacesCore
import Dependencies
import Observation

/// Opens a place in the Wikipedia app, and shows an alert when the app isn't installed.
/// - It tries to open the link, and `false` means Wikipedia isn't installed. It doesn't ask `canOpenURL` first:
///   that needs a list of allowed schemes, and it's deprecated in the iOS 27 SDK.
/// - While one open is running, another is ignored, so two quick taps open Wikipedia once.
@Observable
final class WikipediaOpener {
    nonisolated enum Outcome: Equatable, Sendable {
        case opened
        /// Wikipedia isn't installed: `showsNotInstalledAlert` is set, and the screen shows the alert.
        case notInstalled
        /// Ignored, because another open was running: the second of two quick taps.
        case alreadyOpening
        /// Cancelled before the system answered. No alert.
        case cancelled
    }

    /// The screen shows the alert while this is set, and closing the alert clears it.
    var showsNotInstalledAlert = false

    @ObservationIgnored @Dependency(\.openURL) private var openURL
    @ObservationIgnored private var isOpening = false

    /// Opens Wikipedia's Places tab at `place`, with its name when it has one.
    func open(_ place: Place) async -> Outcome {
        guard !isOpening else { return .alreadyOpening }
        isOpening = true
        defer { isOpening = false }

        if await openURL(WikipediaLink.places(coordinate: place.coordinate, name: place.name)) {
            return .opened
        }
        // `openURL` also answers false to a cancelled open. That doesn't mean Wikipedia is missing, so no alert.
        guard !Task.isCancelled else { return .cancelled }
        showsNotInstalledAlert = true
        return .notInstalled
    }
}
