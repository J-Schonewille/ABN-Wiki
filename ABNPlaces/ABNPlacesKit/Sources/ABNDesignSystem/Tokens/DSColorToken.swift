import SwiftUI
import UIKit

/// One color in its four looks: light, dark, and each with Increase Contrast, written as `#RRGGBB` like in Figma.
/// The palette lives in code instead of an asset catalog, so it reads as one table in code reviews and contrast tests
/// and this way you are FORCED to fill in the lightIncreasedContrast darkIncreasedContrast etc
/// `nonisolated`, because UIKit may resolve a dynamic color on any thread.
nonisolated struct DSColorToken: Hashable, Sendable {
    let light: HexColor
    let dark: HexColor
    let lightIncreasedContrast: HexColor
    let darkIncreasedContrast: HexColor

    init(light: HexColor, dark: HexColor, lightIncreasedContrast: HexColor, darkIncreasedContrast: HexColor) {
        self.light = light
        self.dark = dark
        self.lightIncreasedContrast = lightIncreasedContrast
        self.darkIncreasedContrast = darkIncreasedContrast
    }

    /// The value for these traits. Unspecified counts as light and normal contrast, as in UIKit.
    func hex(for traits: UITraitCollection) -> HexColor {
        let isDark = traits.userInterfaceStyle == .dark
        let isIncreasedContrast = traits.accessibilityContrast == .high
        switch (isDark, isIncreasedContrast) {
        case (false, false): return light
        case (true, false): return dark
        case (false, true): return lightIncreasedContrast
        case (true, true): return darkIncreasedContrast
        }
    }

    /// A color that updates itself when the appearance or the contrast setting changes.
    var uiColor: UIColor {
        let token = self
        return UIColor { @Sendable traits in token.hex(for: traits).uiColor }
    }
}

// MARK: - Palette

/// Light and dark come from the design brief. The Increase Contrast values are ours: every pair gets stronger, and
/// text reaches at least 7:1. `DSColorTokenTests` checks all four looks.
nonisolated extension DSColorToken {
    /// The screen behind the cards.
    static let background = DSColorToken(
        light: "#F7F6FC", dark: "#000000", lightIncreasedContrast: "#F7F6FC", darkIncreasedContrast: "#000000"
    )
    /// Cards, fields and state views.
    static let surface = DSColorToken(
        light: "#FFFFFF", dark: "#17161F", lightIncreasedContrast: "#FFFFFF", darkIncreasedContrast: "#17161F"
    )
    /// The thin line around a card. Only decoration, so it needs no minimum contrast.
    static let separator = DSColorToken(
        light: "#E3E1F2", dark: "#2A2838", lightIncreasedContrast: "#8E8BA8", darkIncreasedContrast: "#77738F"
    )
    /// A text field's border. It shows where an empty field is, so it needs 3:1 (WCAG 1.4.11).
    static let fieldBorder = DSColorToken(
        light: "#8B88A3", dark: "#78758F", lightIncreasedContrast: "#5F5E73", darkIncreasedContrast: "#A9A7BD"
    )
    /// Titles, labels and body text.
    static let textPrimary = DSColorToken(
        light: "#1A1830", dark: "#FFFFFF", lightIncreasedContrast: "#0D0B1F", darkIncreasedContrast: "#FFFFFF"
    )
    /// Subtitles, helper text and messages.
    static let textSecondary = DSColorToken(
        light: "#5F5E73", dark: "#A9A7BD", lightIncreasedContrast: "#424155", darkIncreasedContrast: "#CFCDE0"
    )
    /// The brand purple. The app's `AccentColor` asset has the same four values, so system controls such as alert
    /// buttons match. Change both together.
    static let accent = DSColorToken(
        light: "#534AB7", dark: "#AFA9EC", lightIncreasedContrast: "#3F3699", darkIncreasedContrast: "#CBC6F7"
    )
    /// Text and icons on `accent`.
    static let onAccent = DSColorToken(
        light: "#FFFFFF", dark: "#26215C", lightIncreasedContrast: "#FFFFFF", darkIncreasedContrast: "#1A1645"
    )
    /// A soft purple behind icons and banners.
    static let accentTint = DSColorToken(
        light: "#EEEDFE", dark: "#26215C", lightIncreasedContrast: "#E6E4FC", darkIncreasedContrast: "#26215C"
    )
    /// Errors: field borders, messages and icons.
    static let danger = DSColorToken(
        light: "#A32D2D", dark: "#F09595", lightIncreasedContrast: "#861F1F", darkIncreasedContrast: "#FFB8B8"
    )
    /// Loading placeholders.
    static let skeleton = DSColorToken(
        light: "#E7E5F4", dark: "#262433", lightIncreasedContrast: "#D9D6EC", darkIncreasedContrast: "#363347"
    )
}

// MARK: - Previews

/// Every color in its four looks, with its hex value. The canvas shows the whole palette next to the code.
private struct PalettePreview: View {
    private static let looks: [(title: String, traits: UITraitCollection)] = [
        ("Light", UITraitCollection(userInterfaceStyle: .light)),
        ("Light, more contrast", traits(.light, contrast: .high)),
        ("Dark", UITraitCollection(userInterfaceStyle: .dark)),
        ("Dark, more contrast", traits(.dark, contrast: .high)),
    ]

    var body: some View {
        ScrollView {
            Grid(alignment: .leading, horizontalSpacing: DSSpacing.xSmall, verticalSpacing: DSSpacing.small) {
                GridRow {
                    Text(verbatim: "")
                    ForEach(Self.looks.indices, id: \.self) { index in
                        Text(verbatim: Self.looks[index].title)
                            .font(.caption2.weight(.semibold))
                    }
                }
                ForEach(DSColor.allCases, id: \.self) { color in
                    GridRow {
                        Text(verbatim: "\(color)")
                            .font(.caption.weight(.semibold))
                        ForEach(Self.looks.indices, id: \.self) { index in
                            swatch(color.token.hex(for: Self.looks[index].traits))
                        }
                    }
                }
            }
            .padding(DSSpacing.medium)
        }
    }

    private func swatch(_ hex: HexColor) -> some View {
        VStack(spacing: DSSpacing.xxSmall) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(uiColor: hex.uiColor))
                .overlay {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(.gray.opacity(0.4))
                }
                .frame(height: 32)
            Text(verbatim: hex.description)
                .font(.caption2.monospaced())
        }
    }

    private static func traits(_ style: UIUserInterfaceStyle, contrast: UIAccessibilityContrast) -> UITraitCollection {
        UITraitCollection { traits in
            traits.userInterfaceStyle = style
            traits.accessibilityContrast = contrast
        }
    }
}

#Preview("Palette") {
    PalettePreview()
}
