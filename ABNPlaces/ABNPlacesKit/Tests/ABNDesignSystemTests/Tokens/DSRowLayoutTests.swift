import SwiftUI
import Testing

@testable import ABNDesignSystem

@Suite("Row layout")
struct DSRowLayoutTests {
    @Test(
        "Rows stay side by side up to xxxLarge",
        arguments: DynamicTypeSize.allCases.filter { !$0.isAccessibilitySize }
    )
    func horizontalAtStandardSizes(size: DynamicTypeSize) {
        let layout = DSRowLayout(size)
        #expect(layout == .horizontal)
        #expect(layout.showsTrailingAccessory)
    }

    @Test(
        "Rows stack and drop the chevron at the accessibility sizes",
        arguments: DynamicTypeSize.allCases.filter(\.isAccessibilitySize)
    )
    func verticalAtAccessibilitySizes(size: DynamicTypeSize) {
        let layout = DSRowLayout(size)
        #expect(layout == .vertical)
        #expect(!layout.showsTrailingAccessory)
    }

    @Test("The tests cover all twelve Dynamic Type sizes")
    func coversAllSizes() {
        #expect(DynamicTypeSize.allCases.count == 12)
        #expect(DynamicTypeSize.allCases.filter(\.isAccessibilitySize).count == 5)
    }
}
