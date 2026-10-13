import ABNPlacesCore
import Foundation
import Testing

@testable import ABNPlacesFeature

@Suite("Load failure")
struct LoadFailureTests {
    static let cases: [(error: PlacesAPIError, expected: LoadFailure?)] = [
        (.offline, .offline),
        (.server, .server),
        (.unexpectedData, .unexpectedData),
        (.cancelled, nil),
    ]

    @Test("The screen explains the error", arguments: cases)
    func mapsEachError(_ example: (error: PlacesAPIError, expected: LoadFailure?)) {
        #expect(LoadFailure(example.error) == example.expected)
    }

    @Test(
        "A failed refresh says the earlier places stay",
        arguments: [
            (LoadFailure.offline, "en_US", "Can't connect. Showing earlier results."),
            (.server, "en_US", "Couldn't refresh. Showing earlier results."),
            (.offline, "nl_NL", "Kan geen verbinding maken. Je ziet de eerder geladen plaatsen."),
            (.unexpectedData, "nl_NL", "Vernieuwen is niet gelukt. Je ziet de eerder geladen plaatsen."),
        ]
    )
    func refreshMessage(failure: LoadFailure, locale: String, expected: String) {
        #expect(failure.refreshMessage(in: Locale(identifier: locale)) == expected)
    }

    @Test(
        "VoiceOver announces a failed load as its title, then its message",
        arguments: [
            ("en_US", "Can't connect. Check your internet connection to load places."),
            ("nl_NL", "Kan geen verbinding maken. Controleer je internetverbinding om plaatsen te laden."),
        ]
    )
    func loadAnnouncement(locale: String, expected: String) {
        #expect(LoadFailure.offline.loadAnnouncement(in: Locale(identifier: locale)) == expected)
    }
}
