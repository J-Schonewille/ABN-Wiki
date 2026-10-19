internal import ABNNetworking
import Foundation

extension HTTPClient {
    /// The client every live API uses: a session without a cache, and the app's User-Agent.
    static let live = HTTPClient(session: makeEphemeralSession(), userAgent: appUserAgent)

    static let appUserAgent = makeUserAgent(
        appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    )

    static func makeUserAgent(appVersion: String?) -> String {
        appVersion.map { "ABNPlaces/\($0)" } ?? "ABNPlaces"
    }
}
