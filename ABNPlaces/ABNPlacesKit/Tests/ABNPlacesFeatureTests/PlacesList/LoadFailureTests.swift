import ABNPlacesCore
import Testing

@testable import ABNPlacesFeature

@Suite("Load failure")
struct LoadFailureTests {
    static let cases: [(error: LocationsError, expected: LoadFailure?)] = [
        (.offline, .offline),
        (.server, .server),
        (.unexpectedData, .unexpectedData),
        (.cancelled, nil),
    ]

    @Test("The screen explains the error", arguments: cases)
    func mapsEachError(_ example: (error: LocationsError, expected: LoadFailure?)) {
        #expect(LoadFailure(example.error) == example.expected)
    }
}
