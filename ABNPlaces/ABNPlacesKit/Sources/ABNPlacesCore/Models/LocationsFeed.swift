// Mapping to `Place` happens inside `init(from:)`, so it runs wherever decoding runs: off the main actor,
// because the feed client decodes in a `@concurrent` function (app → URLSession → decode → here).
struct LocationsFeed: Decodable, Sendable {
    // Valid, parsable places without duplicates.
    let places: [Place]
    // for tests / logging
    let skippedCount: Int

    private enum CodingKeys: String, CodingKey {
        case locations
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let entries = try container.decode([FeedEntry].self, forKey: .locations)

        var places: [Place] = []
        var seenIDs: Set<Place.ID> = []
        var skippedCount = 0
        for entry in entries {
            guard let place = entry.place else {
                skippedCount += 1
                continue
            }
            if seenIDs.insert(place.id).inserted {
                places.append(place)
            }
        }
        self.places = places
        self.skippedCount = skippedCount
    }
}

private struct FeedEntry: Decodable {
    let name: String?
    let lat: Double?
    let long: Double?

    private enum CodingKeys: String, CodingKey {
        case name, lat, long
    }

    init(from decoder: any Decoder) {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        name = try? container?.decode(String.self, forKey: .name)
        lat = try? container?.decode(Double.self, forKey: .lat)
        long = try? container?.decode(Double.self, forKey: .long)
    }

    var place: Place? {
        guard let lat, let long, let coordinate = Coordinate(latitude: lat, longitude: long) else {
            return nil
        }
        return Place(name: name, coordinate: coordinate)
    }
}
