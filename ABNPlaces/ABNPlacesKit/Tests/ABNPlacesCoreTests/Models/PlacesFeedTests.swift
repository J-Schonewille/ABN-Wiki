import Foundation
import Testing

@testable import ABNPlacesCore

@Suite("Places feed")
struct PlacesFeedTests {
    static let amsterdamEntry = #"{"name":"Amsterdam","lat":52.3547498,"long":4.8339215}"#

    // MARK: The real feed

    @Test("The real feed gives its four places, the last without a name")
    func decodesTheRealFeed() throws {
        let feed = try JSONDecoder().decode(PlacesFeed.self, from: FeedFixture.data())

        #expect(feed.places == (try FeedFixture.places()))
        #expect(feed.places.count == 4)
        #expect(feed.places.last?.name == nil)
        #expect(feed.skippedCount == 0)
    }

    @Test("Ids stay the same across decodes and reordering")
    func idsAreStableAcrossDecodesAndReordering() throws {
        let first = try JSONDecoder().decode(PlacesFeed.self, from: FeedFixture.data())
        let second = try JSONDecoder().decode(PlacesFeed.self, from: FeedFixture.data())
        let reversed = try decodeFeed(entries: [
            #"{"lat":40.4380638,"long":-3.7495758}"#,
            #"{"name":"Copenhagen","lat":55.6713442,"long":12.523785}"#,
            #"{"name":"Mumbai","lat":19.0823998,"long":72.8111468}"#,
            Self.amsterdamEntry,
        ])

        #expect(second.places.map(\.id) == first.places.map(\.id))
        #expect(reversed.places.map(\.id) == first.places.map(\.id).reversed())
        #expect(Set(first.places.map(\.id)).count == first.places.count)
    }

    // MARK: Entries

    @Test(
        "An unusable entry is skipped and counted",
        arguments: [
            #"{"name":"No latitude","long":4.8339215}"#,
            #"{"name":"No longitude","lat":52.3547498}"#,
            #"{"name":"Latitude 200","lat":200,"long":4.8339215}"#,
            #"{"name":"Longitude -181","lat":52.3547498,"long":-181}"#,
            #"{"name":"String latitude","lat":"52.3547498","long":4.8339215}"#,
            #"{"name":"Null latitude","lat":null,"long":4.8339215}"#,
            #"{"name":"Boolean longitude","lat":52.3547498,"long":true}"#,
            #"{"name":"Huge latitude","lat":1e400,"long":4.8339215}"#,
            "{}",
            "42",
            "null",
            #""Amsterdam""#,
            "[52.3547498,4.8339215]",
        ]
    )
    func skipsAndCountsUnusableEntry(_ entry: String) throws {
        let feed = try decodeFeed(entries: [Self.amsterdamEntry, entry])

        #expect(feed.places == [try FeedFixture.amsterdam()])
        #expect(feed.skippedCount == 1)
    }

    struct KeptCase: Sendable, CustomTestStringConvertible {
        let testDescription: String
        let entry: String
        let expectedName: String?
    }

    static let keptCases: [KeptCase] = [
        KeptCase(
            testDescription: "unknown fields are ignored",
            entry: #"{"name":"Amsterdam","lat":52.3547498,"long":4.8339215,"population":921402,"tags":["capital"]}"#,
            expectedName: "Amsterdam"
        ),
        KeptCase(
            testDescription: "surrounding whitespace is trimmed",
            entry: #"{"name":"  Amsterdam\n","lat":52.3547498,"long":4.8339215}"#,
            expectedName: "Amsterdam"
        ),
        KeptCase(
            testDescription: "empty name is no name",
            entry: #"{"name":"","lat":52.3547498,"long":4.8339215}"#,
            expectedName: nil
        ),
        KeptCase(
            testDescription: "whitespace-only name is no name",
            entry: #"{"name":" \t ","lat":52.3547498,"long":4.8339215}"#,
            expectedName: nil
        ),
        KeptCase(
            testDescription: "null name is no name",
            entry: #"{"name":null,"lat":52.3547498,"long":4.8339215}"#,
            expectedName: nil
        ),
        KeptCase(
            testDescription: "a name that isn't a string is no name",
            entry: #"{"name":42,"lat":52.3547498,"long":4.8339215}"#,
            expectedName: nil
        ),
    ]

    @Test("An entry with a valid coordinate is kept, whatever its name", arguments: keptCases)
    func keepsEntryWithValidCoordinate(_ keptCase: KeptCase) throws {
        let feed = try decodeFeed(entries: [keptCase.entry])

        #expect(feed.places == [Place(name: keptCase.expectedName, coordinate: try .valid(52.3547498, 4.8339215))])
        #expect(feed.skippedCount == 0)
    }

    @Test("Whole numbers and the bounds are valid")
    func acceptsWholeNumbersAndBounds() throws {
        let feed = try decodeFeed(entries: [#"{"lat":90,"long":-180}"#, #"{"lat":0,"long":0}"#])

        #expect(
            feed.places == [
                Place(name: nil, coordinate: try .valid(90, -180)),
                Place(name: nil, coordinate: try .valid(0, 0)),
            ])
    }

    @Test("Duplicates are dropped, and the first is kept")
    func dropsDuplicatesKeepingTheFirst() throws {
        let amsterdam = try FeedFixture.amsterdam()
        let feed = try decodeFeed(entries: [
            Self.amsterdamEntry,
            Self.amsterdamEntry,
            // 1 mm north: the same id, so a duplicate. Keeping the first keeps the exact fixture value.
            #"{"name":"Amsterdam","lat":52.35474981,"long":4.8339215}"#,
            // Same point without a name: a different place.
            #"{"lat":52.3547498,"long":4.8339215}"#,
        ])

        #expect(feed.places == [amsterdam, Place(name: nil, coordinate: amsterdam.coordinate)])
        #expect(feed.skippedCount == 0)
    }

    // MARK: Payload

    @Test("An empty feed decodes to no places")
    func decodesAnEmptyFeed() throws {
        let feed = try decodeFeed(entries: [])

        #expect(feed.places.isEmpty)
        #expect(feed.skippedCount == 0)
    }

    @Test(
        "A payload without a locations array fails",
        arguments: ["{}", #"{"locations":null}"#, #"{"locations":{}}"#, #"{"places":[]}"#, "[]", "not json"]
    )
    func rejectsPayloadWithoutLocationsArray(_ json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PlacesFeed.self, from: Data(json.utf8))
        }
    }

    // MARK: Helpers

    private func decodeFeed(entries: [String]) throws -> PlacesFeed {
        let json = #"{"locations":["# + entries.joined(separator: ",") + "]}"
        return try JSONDecoder().decode(PlacesFeed.self, from: Data(json.utf8))
    }
}
