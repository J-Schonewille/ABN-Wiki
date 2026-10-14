import ABNPlacesCore
import ABNPlacesUITestContract
import XCTest

/// Finds elements by the identifiers the screen shares with the tests, never by position or copy.
@MainActor
struct PlacesListScreen {
    let app: XCUIApplication

    // MARK: Elements

    func card(_ place: Place) -> XCUIElement {
        app.buttons[AccessibilityID.PlacesList.card(id: place.id)]
    }

    var loadFailure: XCUIElement {
        app.otherElements[AccessibilityID.PlacesList.loadFailure]
    }

    var retryButton: XCUIElement {
        app.buttons[AccessibilityID.PlacesList.retry]
    }

    var addPlaceButton: XCUIElement {
        app.buttons[AccessibilityID.PlacesList.addPlace]
    }

    var refreshButton: XCUIElement {
        app.buttons[AccessibilityID.PlacesList.refresh]
    }

    // MARK: Waits

    func waitForCards(of places: [Place], file: StaticString = #filePath, line: UInt = #line) {
        for place in places {
            XCTAssertTrue(
                card(place).waitForExistence(timeout: PlacesUITestCase.timeout),
                "No card for \(place.id)",
                file: file,
                line: line
            )
        }
    }

    /// Checks the cards come in this order: row by row, left to right within a row.
    func assertCardOrder(_ places: [Place], file: StaticString = #filePath, line: UInt = #line) {
        let frames = places.map { card($0).frame }
        for (index, (frame, next)) in zip(frames, frames.dropFirst()).enumerated() {
            let isSameRow = frame.minY < next.maxY && next.minY < frame.maxY
            XCTAssertTrue(
                isSameRow ? frame.minX < next.minX : frame.maxY <= next.minY,
                "\(places[index + 1].id) comes before \(places[index].id)",
                file: file,
                line: line
            )
        }
    }

    func waitForNoCard(of place: Place, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            card(place).waitForNonExistence(timeout: PlacesUITestCase.timeout),
            "The card for \(place.id) is still there",
            file: file,
            line: line
        )
    }

    func waitForLoadFailure(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            loadFailure.waitForExistence(timeout: PlacesUITestCase.timeout),
            "The load failure didn't show",
            file: file,
            line: line
        )
    }

    // MARK: Actions

    /// Starts on `element`, because a drag from the navigation bar doesn't refresh. Pulls half the window's height,
    /// because an iPad needs a longer pull.
    func pullToRefresh(from element: XCUIElement) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let distance = app.windows.firstMatch.frame.height / 2
        start.press(
            forDuration: 0.2,
            thenDragTo: start.withOffset(CGVector(dx: 0, dy: distance)),
            withVelocity: .slow,
            thenHoldForDuration: 0.5
        )
    }

    /// At AX5 the tap scrolls to the button first.
    func openCreatePlace(file: StaticString = #filePath, line: UInt = #line) -> CreatePlaceScreen {
        XCTAssertTrue(
            addPlaceButton.waitForExistence(timeout: PlacesUITestCase.timeout),
            "There's no Add place button",
            file: file,
            line: line
        )
        addPlaceButton.tap()
        let sheet = CreatePlaceScreen(app: app)
        sheet.waitUntilShown(file: file, line: line)
        return sheet
    }

    // MARK: Accessibility

    func performAccessibilityAudit() throws {
        try app.performAccessibilityAudit()
    }
}
