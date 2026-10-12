import ABNPlacesCore
import Testing

@Suite("Place")
struct PlaceTests {
    @Test("The id is the coordinate's text plus the name")
    func idIsCoordinateTextPlusName() throws {
        let amsterdam = Place(name: "Amsterdam", coordinate: try .valid(52.3547498, 4.8339215))
        let unnamed = Place(name: nil, coordinate: try .valid(40.4380638, -3.7495758))

        #expect(amsterdam.id == "52.3547498,4.8339215,Amsterdam")
        #expect(unnamed.id == "40.4380638,-3.7495758")
    }

    @Test("The same content gives the same id")
    func sameContentGivesSameID() throws {
        let place = Place(name: "Amsterdam", coordinate: try .valid(52.3547498, 4.8339215))

        // Built again, with untrimmed whitespace, and 1 mm away: below the 7 decimals the id keeps.
        let again = Place(name: "Amsterdam", coordinate: try .valid(52.3547498, 4.8339215))
        let untrimmed = Place(name: " Amsterdam\n", coordinate: try .valid(52.3547498, 4.8339215))
        let millimetreAway = Place(name: "Amsterdam", coordinate: try .valid(52.35474981, 4.8339215))

        #expect(again.id == place.id)
        #expect(untrimmed.id == place.id)
        #expect(millimetreAway.id == place.id)
    }

    @Test("Negative zero gives the same id as zero")
    func negativeZeroGivesSameIDAsZero() throws {
        let origin = Place(name: nil, coordinate: try .valid(0, 0))
        let negativeZero = Place(name: nil, coordinate: try .valid(-0.0, -0.00000001))

        #expect(negativeZero.id == origin.id)
        #expect(origin.id == "0,0")
    }

    @Test("Different places get different ids")
    func differentPlacesGetDifferentIDs() throws {
        let coordinate = try Coordinate.valid(52.3547498, 4.8339215)
        let places = [
            Place(name: "Amsterdam", coordinate: coordinate),
            Place(name: nil, coordinate: coordinate),
            Place(name: "Amsterdam Zuid", coordinate: coordinate),
            Place(name: "Amsterdam", coordinate: try .valid(52.3547499, 4.8339215)),
            Place(name: "Amsterdam", coordinate: try .valid(4.8339215, 52.3547498)),
        ]

        #expect(Set(places.map(\.id)).count == places.count)
    }

    @Test("A comma in the name can't make two ids collide")
    func commaInNameKeepsIDsApart() throws {
        // "1,2" + name "3" and "1" + ... can't meet: the coordinate texts never contain a comma themselves.
        let withComma = Place(name: "Amsterdam, Noord", coordinate: try .valid(52.3547498, 4.8339215))
        let without = Place(name: "Amsterdam", coordinate: try .valid(52.3547498, 4.8339215))

        #expect(withComma.id == "52.3547498,4.8339215,Amsterdam, Noord")
        #expect(withComma.id != without.id)
    }

    @Test(
        "The name is trimmed, and a blank name is no name",
        arguments: [
            ("Amsterdam", "Amsterdam"),
            ("  Den Haag \n", "Den Haag"),
            ("", nil),
            ("   ", nil),
            ("\t\n", nil),
            (nil, nil),
        ] as [(String?, String?)]
    )
    func trimsNameAndTreatsBlankAsNoName(name: String?, expected: String?) throws {
        let place = Place(name: name, coordinate: try .valid(0, 0))

        #expect(place.name == expected)
    }
}
