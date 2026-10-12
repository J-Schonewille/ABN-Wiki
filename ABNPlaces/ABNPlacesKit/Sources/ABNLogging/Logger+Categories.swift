import Foundation
import os

/// Logger for DEBUG builds. Release builds wont see anything
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.jschonewille.ABNPlaces"

    /// Requests and decoding.
    public static let network = debugBuildsOnly(category: "Network")
    /// Loading the places.
    public static let locations = debugBuildsOnly(category: "Locations")

    private static func debugBuildsOnly(category: String) -> Logger {
        #if DEBUG
        Logger(subsystem: subsystem, category: category)
        #else
        Logger(.disabled)
        #endif
    }
}
