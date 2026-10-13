import Foundation
import os

/// These loggers are off in release builds.
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.jschonewille.ABNPlaces"

    /// Requests and decoding.
    public static let network = debugBuildsOnly(category: "Network")
    /// Loading the places.
    public static let places = debugBuildsOnly(category: "Places")

    private static func debugBuildsOnly(category: String) -> Logger {
        #if DEBUG
        Logger(subsystem: subsystem, category: category)
        #else
        Logger(.disabled)
        #endif
    }
}
