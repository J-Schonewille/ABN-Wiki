import UIKit

/// An sRGB color written as `"#RRGGBB"`, the way Figma and other design tools show it. Upper and lower case both
/// work. Anything else stops the app straight away, so a typo can't slip through: the contrast tests load every
/// color.
nonisolated struct HexColor: ExpressibleByStringLiteral, Hashable, Sendable, CustomStringConvertible {
    let rgb: UInt32

    init(stringLiteral text: String) {
        let digits = text.dropFirst()
        guard text.first == "#", digits.count == 6, digits.allSatisfy(\.isHexDigit),
            let rgb = UInt32(digits, radix: 16)
        else {
            preconditionFailure("A color is written as #RRGGBB, not \(text)")
        }
        self.rgb = rgb
    }

    /// `#RRGGBB`, in upper case.
    var description: String {
        String(format: "#%06X", rgb)
    }

    var uiColor: UIColor {
        UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
