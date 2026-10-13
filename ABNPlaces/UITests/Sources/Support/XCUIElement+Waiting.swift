import XCTest

extension XCUIElement {
    @MainActor
    func waitUntilHittable(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            wait(for: \.isHittable, toEqual: true, timeout: PlacesUITestCase.timeout),
            "The element isn't hittable",
            file: file,
            line: line
        )
    }
}
