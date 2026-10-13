import ABNPlacesUITestContract
import UIKit
import XCTest

@MainActor
struct CreatePlaceScreen {
    let app: XCUIApplication

    // MARK: Elements

    var nameField: XCUIElement {
        app.textFields[AccessibilityID.CreatePlace.name]
    }

    var latitudeField: XCUIElement {
        app.textFields[AccessibilityID.CreatePlace.latitude]
    }

    var longitudeField: XCUIElement {
        app.textFields[AccessibilityID.CreatePlace.longitude]
    }

    var saveButton: XCUIElement {
        app.buttons[AccessibilityID.CreatePlace.save]
    }

    var cancelButton: XCUIElement {
        app.buttons[AccessibilityID.CreatePlace.cancel]
    }

    // MARK: Waits

    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            latitudeField.waitForExistence(timeout: PlacesUITestCase.timeout),
            "The create-place sheet didn't open",
            file: file,
            line: line
        )
    }

    /// `hasFocus` stays false for an iOS text field, so this waits for `hasKeyboardFocus` instead.
    func waitForKeyboardFocus(on field: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let hasKeyboardFocus = NSPredicate(format: "hasKeyboardFocus == true")
        let focused = XCTNSPredicateExpectation(predicate: hasKeyboardFocus, object: field)
        XCTAssertEqual(
            XCTWaiter.wait(for: [focused], timeout: PlacesUITestCase.timeout),
            .completed,
            "The field didn't get keyboard focus",
            file: file,
            line: line
        )
    }

    // MARK: Actions

    func type(_ text: String, into field: XCUIElement) {
        field.tap()
        field.typeText(text)
    }

    func save() {
        saveButton.tap()
    }

    func cancel(file: StaticString = #filePath, line: UInt = #line) {
        cancelButton.tap()
        waitUntilClosed(file: file, line: line)
    }

    func waitUntilClosed(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            latitudeField.waitForNonExistence(timeout: PlacesUITestCase.timeout),
            "The create-place sheet didn't close",
            file: file,
            line: line
        )
    }

    // MARK: Accessibility

    /// On iPad, skips "Potentially inaccessible text" with no element: it's the dimmed list around the sheet, which
    /// VoiceOver rightly can't reach. The iPhone run still checks the sheet.
    func performAccessibilityAudit() throws {
        let listShowsAroundTheSheet = UIDevice.current.userInterfaceIdiom == .pad
        try app.performAccessibilityAudit { issue in
            listShowsAroundTheSheet && issue.auditType == .elementDetection && issue.element == nil
                && issue.compactDescription == "Potentially inaccessible text"
        }
    }
}
