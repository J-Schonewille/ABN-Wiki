import Foundation
import Testing

@testable import ABNNetworking
@testable import ABNPlacesCore

@Suite("Live HTTP client")
struct HTTPClientLiveTests {
    @Test("The live client uses a session without a cache, and the app's User-Agent")
    func liveClientUsesSessionWithoutCacheAndTheAppsUserAgent() {
        #expect(HTTPClient.live.session.configuration.urlCache == nil)
        #expect(HTTPClient.live.userAgent == HTTPClient.appUserAgent)
        #expect(HTTPClient.appUserAgent.hasPrefix("ABNPlaces"))
    }

    @Test("The User-Agent is the app's name and version")
    func userAgentIsTheAppsNameAndVersion() {
        #expect(HTTPClient.makeUserAgent(appVersion: "1.2") == "ABNPlaces/1.2")
        #expect(HTTPClient.makeUserAgent(appVersion: nil) == "ABNPlaces")
    }
}
