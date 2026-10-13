import ABNPlacesCore
import Dependencies
import Observation

@Observable
final class CreatePlaceModel {
    nonisolated enum Field: Hashable, Sendable {
        case name, latitude, longitude
    }

    nonisolated enum SaveOutcome: Equatable, Sendable {
        case invalid(firstInvalidField: Field)
        case saved(Place)
        /// The place was saved before. The sheet still closes.
        case alreadySaved(Place)
    }

    var name = ""
    var latitude = ""
    var longitude = ""

    private(set) var showsErrors = false

    @ObservationIgnored @Dependency(\.placesLocalStorage) private var placesLocalStorage

    var latitudeError: CoordinateInputError? {
        guard showsErrors, case .failure(let error) = parsedLatitude else { return nil }
        return error
    }

    var longitudeError: CoordinateInputError? {
        guard showsErrors, case .failure(let error) = parsedLongitude else { return nil }
        return error
    }

    func save() -> SaveOutcome {
        showsErrors = true
        switch (parsedLatitude, parsedLongitude) {
        case (.failure, _):
            return .invalid(firstInvalidField: .latitude)
        case (_, .failure):
            return .invalid(firstInvalidField: .longitude)
        case (.success(let latitude), .success(let longitude)):
            // The parser checks `Coordinate`'s ranges, so this never fails.
            guard let coordinate = Coordinate(latitude: latitude, longitude: longitude) else {
                preconditionFailure("Parsed degrees out of range: \(latitude), \(longitude)")
            }
            let place = Place(name: name, coordinate: coordinate)
            return placesLocalStorage.save(place) ? .saved(place) : .alreadySaved(place)
        }
    }

    private var parsedLatitude: Result<Double, CoordinateInputError> {
        Result { () throws(CoordinateInputError) in try CoordinateInputParser.latitude(from: latitude) }
    }

    private var parsedLongitude: Result<Double, CoordinateInputError> {
        Result { () throws(CoordinateInputError) in try CoordinateInputParser.longitude(from: longitude) }
    }
}
