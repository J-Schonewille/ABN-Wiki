import CoreGraphics
import Testing

@testable import ABNDesignSystem

@Suite("Button shape")
struct DSButtonStyleTests {
    @Test("A one-line button is a capsule")
    func oneLineButtonIsCapsule() {
        #expect(DSButtonShape.cornerRadius(height: 46, maxCornerRadius: 26) == 23)
    }

    @Test("A wrapped button keeps its corners and stops being a capsule")
    func wrappedButtonCapsCorners() {
        #expect(DSButtonShape.cornerRadius(height: 120, maxCornerRadius: 26) == 26)
    }
}
