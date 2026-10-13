import Testing
import UIKit

@testable import ABNDesignSystem

@Suite("Hex color")
struct HexColorTests {
    @Test("A #RRGGBB string reads as its color, in upper or lower case", arguments: ["#534AB7", "#534ab7"])
    func readsHexString(_ text: String) {
        #expect(HexColor(stringLiteral: text).rgb == 0x534AB7)
    }

    @Test("It's written back as #RRGGBB, in upper case")
    func writesHexString() {
        let color: HexColor = "#534ab7"

        #expect(color.description == "#534AB7")
    }

    @Test("Each channel ends up in the right place")
    func readsChannels() {
        let color: HexColor = "#FF8000"
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(red == 1)
        #expect(abs(green - 128.0 / 255) < 0.000_1)
        #expect(blue == 0)
        #expect(alpha == 1)
    }
}
