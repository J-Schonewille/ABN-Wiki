import UIKit

@testable import ABNDesignSystem

/// WCAG 2.2 contrast between two colors.
enum WCAG {
    static func contrastRatio(_ first: UIColor, _ second: UIColor) -> Double {
        let lighter = max(luminance(first), luminance(second))
        let darker = min(luminance(first), luminance(second))
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func contrastRatio(_ first: HexColor, _ second: HexColor) -> Double {
        contrastRatio(first.uiColor, second.uiColor)
    }

    private static func luminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// How bright a color channel really is. Screens store channels on a curve, and contrast needs the real light.
    private static func linear(_ channel: CGFloat) -> Double {
        let value = Double(channel)
        return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}
