import ABNPlacesCore
import Dependencies
import Testing

@testable import ABNPlacesFeature

@MainActor
@Suite("Create place")
struct CreatePlaceModelTests {
    // MARK: Valid input

    struct ValidInput: Sendable, CustomTestStringConvertible {
        let latitude: String
        let longitude: String
        let expectedLatitude: Double
        let expectedLongitude: Double

        var testDescription: String { "“\(latitude)”, “\(longitude)”" }
    }

    nonisolated static let validInputs = [
        ValidInput(latitude: "52,3547", longitude: "4,8339", expectedLatitude: 52.3547, expectedLongitude: 4.8339),
        ValidInput(latitude: "52.3547", longitude: "4.8339", expectedLatitude: 52.3547, expectedLongitude: 4.8339),
        // Madrid: a negative longitude, also with the typographic minus some keyboards insert.
        ValidInput(latitude: "40,4381", longitude: "-3,7496", expectedLatitude: 40.4381, expectedLongitude: -3.7496),
        ValidInput(latitude: "40,4381", longitude: "−3,7496", expectedLatitude: 40.4381, expectedLongitude: -3.7496),
        ValidInput(latitude: "  52,35 ", longitude: " 4,83  ", expectedLatitude: 52.35, expectedLongitude: 4.83),
        ValidInput(latitude: "90", longitude: "-180", expectedLatitude: 90, expectedLongitude: -180),
        ValidInput(latitude: "-90", longitude: "180", expectedLatitude: -90, expectedLongitude: 180),
    ]

    @Test("Valid input saves the place in the local storage", arguments: validInputs)
    func validInputSaves(_ input: ValidInput) throws {
        let storage = PlacesLocalStorage.inMemory()
        let model = Self.model(saving: storage)
        model.latitude = input.latitude
        model.longitude = input.longitude

        let coordinate = try #require(Coordinate(latitude: input.expectedLatitude, longitude: input.expectedLongitude))
        let place = Place(name: nil, coordinate: coordinate)
        #expect(model.save() == .saved(place))
        #expect(storage.places() == [place])
        #expect(model.latitudeError == nil)
        #expect(model.longitudeError == nil)
    }

    @Test("Saving a place that is saved already says so, and keeps one")
    func savingTwice() throws {
        let coordinate = try #require(Coordinate(latitude: 52.3547, longitude: 4.8339))
        let place = Place(name: nil, coordinate: coordinate)
        let storage = PlacesLocalStorage.inMemory([place])
        let model = Self.model(saving: storage)
        model.latitude = "52,3547"
        model.longitude = "4,8339"

        #expect(model.save() == .alreadySaved(place))
        #expect(storage.places() == [place])
    }

    // MARK: Invalid input

    struct InvalidInput: Sendable, CustomTestStringConvertible {
        let latitude: String
        let longitude: String
        let firstInvalidField: CreatePlaceModel.Field
        let latitudeError: CoordinateInputError?
        let longitudeError: CoordinateInputError?

        var testDescription: String { "“\(latitude)”, “\(longitude)”" }
    }

    nonisolated static let invalidInputs = [
        InvalidInput(
            latitude: "", longitude: "", firstInvalidField: .latitude,
            latitudeError: .empty, longitudeError: .empty
        ),
        InvalidInput(
            latitude: "52,3547", longitude: "   ", firstInvalidField: .longitude,
            latitudeError: nil, longitudeError: .empty
        ),
        InvalidInput(
            latitude: "90,0001", longitude: "4,8339", firstInvalidField: .latitude,
            latitudeError: .outOfRange(-90...90), longitudeError: nil
        ),
        InvalidInput(
            latitude: "52,3547", longitude: "180,5", firstInvalidField: .longitude,
            latitudeError: nil, longitudeError: .outOfRange(-180...180)
        ),
        InvalidInput(
            latitude: "Amsterdam", longitude: "4,8339", firstInvalidField: .latitude,
            latitudeError: .notANumber, longitudeError: nil
        ),
        // Grouping is rejected: "1.234,5" reads differently in Dutch and English.
        InvalidInput(
            latitude: "52,3547", longitude: "1.234,5", firstInvalidField: .longitude,
            latitudeError: nil, longitudeError: .notANumber
        ),
        // When both are wrong, focus goes to the first one on screen.
        InvalidInput(
            latitude: "200", longitude: "abc", firstInvalidField: .latitude,
            latitudeError: .outOfRange(-90...90), longitudeError: .notANumber
        ),
    ]

    @Test("Invalid input shows the errors and reports the first invalid field", arguments: invalidInputs)
    func invalidInputReportsTheFirstField(_ input: InvalidInput) {
        let storage = PlacesLocalStorage.inMemory()
        let model = Self.model(saving: storage)
        model.latitude = input.latitude
        model.longitude = input.longitude

        #expect(model.save() == .invalid(firstInvalidField: input.firstInvalidField))
        #expect(model.latitudeError == input.latitudeError)
        #expect(model.longitudeError == input.longitudeError)
        #expect(storage.places().isEmpty)
    }

    @Test("Errors appear after the first save, then follow every edit")
    func errorsAppearAfterTheFirstSave() {
        let model = Self.model()
        model.latitude = "200"

        #expect(model.latitudeError == nil)

        _ = model.save()
        #expect(model.latitudeError == .outOfRange(-90...90))
        #expect(model.longitudeError == .empty)

        model.latitude = "52,3547"
        #expect(model.latitudeError == nil)
        model.longitude = "x"
        #expect(model.longitudeError == .notANumber)
    }

    // MARK: The optional name

    @Test(
        "The optional name is trimmed, and a blank name is left out",
        arguments: [
            ("Amsterdam", "Amsterdam"),
            ("  Amsterdam centrum \n", "Amsterdam centrum"),
            ("", nil),
            ("   ", nil),
        ] as [(String, String?)]
    )
    func nameIsTrimmed(typed: String, expected: String?) {
        let model = Self.model()
        model.name = typed
        model.latitude = "52,3547"
        model.longitude = "4,8339"

        guard case .saved(let place) = model.save() else {
            Issue.record("The place wasn't saved")
            return
        }
        #expect(place.name == expected)
    }

    /// Made inside `withDependencies`, because `@Dependency` reads its values when the model is created.
    private static func model(saving storage: PlacesLocalStorage = .inMemory()) -> CreatePlaceModel {
        withDependencies {
            $0.placesLocalStorage = storage
        } operation: {
            CreatePlaceModel()
        }
    }
}
