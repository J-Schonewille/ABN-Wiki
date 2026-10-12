import ABNPlacesCore
import Testing

@Suite("Coordinate")
struct CoordinateTests {
    @Test(
        "Finite values in range make a coordinate",
        arguments: [
            (0, 0),
            (90, 180),
            (-90, -180),
            (52.3547498, 4.8339215),
            (40.4380638, -3.7495758),
        ] as [(Double, Double)]
    )
    func acceptsFiniteValuesInRange(latitude: Double, longitude: Double) throws {
        let coordinate = try #require(Coordinate(latitude: latitude, longitude: longitude))

        #expect(coordinate.latitude == latitude)
        #expect(coordinate.longitude == longitude)
    }

    @Test(
        "Values out of range, NaN and infinity make none",
        arguments: [
            (90.0000001, 0),
            (-90.0000001, 0),
            (0, 180.0000001),
            (0, -180.0000001),
            (200, 10),
            (.nan, 0),
            (0, .nan),
            (.infinity, 0),
            (0, -.infinity),
        ] as [(Double, Double)]
    )
    func rejectsOutOfRangeAndNonFiniteValues(latitude: Double, longitude: Double) {
        #expect(Coordinate(latitude: latitude, longitude: longitude) == nil)
    }
}
