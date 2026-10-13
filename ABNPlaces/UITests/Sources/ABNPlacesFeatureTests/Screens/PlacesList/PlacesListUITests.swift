import ABNPlacesCore
import ABNPlacesUITestContract
import XCTest

final class PlacesListUITests: PlacesUITestCase {
    @MainActor
    func testTheFeedShowsEveryPlaceAsACard() {
        let list = launch(.success)

        list.waitForCards(of: .preview)
    }

    @MainActor
    func testAFailedLoadOffersRetryAndAddingAPlace() {
        let list = launch(.offline)

        list.waitForLoadFailure()
        list.retryButton.waitUntilHittable()
        // No dead end: adding a place doesn't need the feed.
        list.addPlaceButton.waitUntilHittable()
    }

    /// At AX5 "Add place" isn't pinned: it's below the error, reached by scrolling.
    @MainActor
    func testAtTheLargestTextSizeAFailedLoadStillOffersAddingAPlace() {
        let list = launch(.offline, textSize: .accessibility5)
        list.waitForLoadFailure()

        let sheet = list.openCreatePlace()

        sheet.cancel()
    }

    @MainActor
    func testPullingToRefreshShowsTheNewPlaces() {
        let list = launch(.updates)
        list.waitForCards(of: .preview)

        list.pullToRefresh(from: list.card(.amsterdam))

        // The refresh takes two seconds and brings Amsterdam only.
        list.waitForNoCard(of: .mumbai)
        list.waitForCards(of: [.amsterdam])
    }

    @MainActor
    func testPullingToRefreshAfterAFailedLoadShowsThePlaces() {
        let list = launch(.recovers)
        list.waitForLoadFailure()

        list.pullToRefresh(from: list.loadFailure)

        list.waitForCards(of: .preview)
    }

    // MARK: Accessibility

    /// Checks copy, because here the words are the behavior: coordinates in words, and "Unnamed place".
    @MainActor
    func testVoiceOverReadsTheCards() {
        let list = launch(.success)
        list.waitForCards(of: [.amsterdam, .unnamedMadrid])

        XCTAssertEqual(list.card(.amsterdam).label, "Amsterdam, 52.35 degrees north, 4.83 degrees east")
        XCTAssertEqual(list.card(.unnamedMadrid).label, "Unnamed place, 40.44 degrees north, 3.75 degrees west")
    }

    @MainActor
    func testThePlacesListPassesTheAudit() throws {
        let list = launch(.success)
        list.waitForCards(of: .preview)

        try list.performAccessibilityAudit()
    }

    @MainActor
    func testTheLoadFailurePassesTheAudit() throws {
        let list = launch(.offline)
        list.waitForLoadFailure()

        try list.performAccessibilityAudit()
    }
}
