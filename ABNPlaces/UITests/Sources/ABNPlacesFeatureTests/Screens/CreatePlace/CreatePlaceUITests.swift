import ABNPlacesCore
import ABNPlacesUITestContract
import XCTest

final class CreatePlaceUITests: PlacesUITestCase {
    @MainActor
    func testSavingAddsThePlaceAfterTheFeedsPlaces() throws {
        let list = launch(.success)
        let sheet = list.openCreatePlace()
        sheet.type("Vondelpark", into: sheet.nameField)
        sheet.type("52,358", into: sheet.latitudeField)
        sheet.type("4,8686", into: sheet.longitudeField)

        sheet.save()

        sheet.waitUntilClosed()
        let coordinate = try XCTUnwrap(Coordinate(latitude: 52.358, longitude: 4.8686))
        let places = [Place].preview + [Place(name: "Vondelpark", coordinate: coordinate)]
        list.waitForCards(of: places)
        list.assertCardOrder(places)
    }

    @MainActor
    func testSavingMovesFocusToTheFirstInvalidField() {
        let sheet = launch(.success).openCreatePlace()
        sheet.type("4,8339", into: sheet.longitudeField)

        sheet.save()

        // Latitude is empty, so focus moves there: what's typed next lands in it.
        sheet.waitForKeyboardFocus(on: sheet.latitudeField)
        sheet.app.typeText("52,3547")
        XCTAssertEqual(sheet.latitudeField.value as? String, "52,3547")
        XCTAssertEqual(sheet.longitudeField.value as? String, "4,8339")
    }

    @MainActor
    func testCancelClosesTheSheet() {
        let list = launch(.success)
        let sheet = list.openCreatePlace()

        sheet.cancel()

        list.addPlaceButton.waitUntilHittable()
    }

    // MARK: Accessibility

    /// Checks copy, because here the words are the behavior: a field's error is part of its label.
    @MainActor
    func testVoiceOverReadsAFieldsErrorWithTheField() {
        let sheet = launch(.success).openCreatePlace()
        sheet.type("52,3547", into: sheet.latitudeField)
        sheet.type("200", into: sheet.longitudeField)

        sheet.save()

        let longitudeWithError = "Longitude, Enter a number between −180 and 180."
        XCTAssertTrue(
            sheet.longitudeField.wait(for: \.label, toEqual: longitudeWithError, timeout: Self.timeout),
            "Longitude reads \"\(sheet.longitudeField.label)\""
        )
        XCTAssertEqual(sheet.longitudeField.value as? String, "200")
        XCTAssertEqual(sheet.latitudeField.label, "Latitude")
    }

    @MainActor
    func testTheSheetWithErrorsPassesTheAudit() throws {
        let sheet = launch(.success).openCreatePlace()
        sheet.save()
        // Both fields are empty, so focus moves to Latitude.
        sheet.waitForKeyboardFocus(on: sheet.latitudeField)

        try sheet.performAccessibilityAudit()
    }
}
