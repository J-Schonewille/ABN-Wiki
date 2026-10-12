import ABNPlacesCore
import Foundation
import Testing

extension Coordinate {
    // A coordinate the test expects to be valid. Records an issue and throws if it isn't.
    static func valid(_ latitude: Double, _ longitude: Double) throws -> Coordinate {
        try #require(Coordinate(latitude: latitude, longitude: longitude))
    }
}

enum FeedFixture {
    // `Fixtures/locations.json`, a copy of the real feed.
    static func data() throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "locations", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    static func amsterdam() throws -> Place {
        Place(name: "Amsterdam", coordinate: try .valid(52.3547498, 4.8339215))
    }

    static func places() throws -> [Place] {
        [
            try amsterdam(),
            Place(name: "Mumbai", coordinate: try .valid(19.0823998, 72.8111468)),
            Place(name: "Copenhagen", coordinate: try .valid(55.6713442, 12.523785)),
            Place(name: nil, coordinate: try .valid(40.4380638, -3.7495758)),
        ]
    }
}
