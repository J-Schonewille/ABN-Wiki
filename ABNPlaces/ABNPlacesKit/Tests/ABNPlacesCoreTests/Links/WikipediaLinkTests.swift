import ABNPlacesCore
import Foundation
import Testing

@Suite("Wikipedia link")
struct WikipediaLinkTests {
    struct LinkCase: Sendable, CustomTestStringConvertible {
        let testDescription: String
        let latitude: Double
        let longitude: Double
        var name: String?
        let expected: String
    }

    /// The contract shared with the Wikipedia app's parser tests, as exact strings: its tests accept every one.
    static let contractVectors: [LinkCase] = [
        LinkCase(
            testDescription: "Amsterdam",
            latitude: 52.3547498, longitude: 4.8339215, name: "Amsterdam",
            expected: "wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam"
        ),
        LinkCase(
            testDescription: "Madrid: negative longitude, no name",
            latitude: 40.4380638, longitude: -3.7495758,
            expected: "wikipedia://places?lat=40.4380638&lon=-3.7495758"
        ),
        LinkCase(
            testDescription: "bounds",
            latitude: 90, longitude: -180,
            expected: "wikipedia://places?lat=90&lon=-180"
        ),
        LinkCase(
            testDescription: "origin",
            latitude: 0, longitude: 0,
            expected: "wikipedia://places?lat=0&lon=0"
        ),
        LinkCase(
            testDescription: "name with spaces and &",
            latitude: 52.3731, longitude: 4.8926, name: "Dam & Royal Palace",
            expected: "wikipedia://places?lat=52.3731&lon=4.8926&name=Dam%20%26%20Royal%20Palace"
        ),
    ]

    @Test("Builds each link of the contract with the Wikipedia app", arguments: contractVectors)
    func buildsContractVector(_ vector: LinkCase) throws {
        let coordinate = try Coordinate.valid(vector.latitude, vector.longitude)

        #expect(WikipediaLink.places(coordinate: coordinate, name: vector.name).absoluteString == vector.expected)
    }

    static let numberFormattingCases: [LinkCase] = [
        LinkCase(
            testDescription: "1e-07 is written out",  // String(describing: 0.0000001) gives "1e-07"
            latitude: 0.0000001, longitude: -0.0000001,
            expected: "wikipedia://places?lat=0.0000001&lon=-0.0000001"
        ),
        LinkCase(
            testDescription: "rounds to zero, never to -0",
            latitude: 0.00000001, longitude: -0.00000001,
            expected: "wikipedia://places?lat=0&lon=0"
        ),
        LinkCase(
            testDescription: "negative zero",
            latitude: -0.0, longitude: 0,
            expected: "wikipedia://places?lat=0&lon=0"
        ),
        LinkCase(
            testDescription: "at most 7 decimals",
            latitude: 52.35474989, longitude: 4.83392151,
            expected: "wikipedia://places?lat=52.3547499&lon=4.8339215"
        ),
        LinkCase(
            testDescription: "no trailing zeros",
            latitude: 12.5, longitude: 100,
            expected: "wikipedia://places?lat=12.5&lon=100"
        ),
    ]

    @Test("Writes numbers in fixed notation, with at most 7 decimals", arguments: numberFormattingCases)
    func writesFixedNotationWithAtMostSevenDecimals(_ formattingCase: LinkCase) throws {
        let coordinate = try Coordinate.valid(formattingCase.latitude, formattingCase.longitude)

        #expect(WikipediaLink.places(coordinate: coordinate).absoluteString == formattingCase.expected)
    }

    @Test(
        "Writes only numbers the Wikipedia app's parser accepts",
        arguments: [-180, -179.99999995, -90, -3.7495758, -0.00000004, 0, 1e-7, 4.8339215, 89.99999999, 90, 180]
    )
    func writesNumbersTheWikipediaParserAccepts(_ degrees: Double) throws {
        let coordinate = try Coordinate.valid(min(max(degrees, -90), 90), degrees)
        let url = WikipediaLink.places(coordinate: coordinate)

        let queryItems = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(queryItems.map(\.name) == ["lat", "lon"])
        for item in queryItems {
            let value = try #require(item.value)
            #expect(value.wholeMatch(of: #/-?[0-9]{1,3}(?:\.[0-9]{1,15})?/#) != nil, "\(item.name)=\(value)")
        }
    }

    @Test(
        "Includes the name only when it isn't blank",
        arguments: [
            (nil, "wikipedia://places?lat=52.3547498&lon=4.8339215"),
            ("", "wikipedia://places?lat=52.3547498&lon=4.8339215"),
            (" \n", "wikipedia://places?lat=52.3547498&lon=4.8339215"),
            (" Amsterdam\n", "wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam"),
            ("C++ Café", "wikipedia://places?lat=52.3547498&lon=4.8339215&name=C++%20Caf%C3%A9"),  // literal plus
        ] as [(String?, String)]
    )
    func includesNameOnlyWhenNotBlank(name: String?, expected: String) throws {
        let url = WikipediaLink.places(coordinate: try .valid(52.3547498, 4.8339215), name: name)

        #expect(url.absoluteString == expected)
    }
}
