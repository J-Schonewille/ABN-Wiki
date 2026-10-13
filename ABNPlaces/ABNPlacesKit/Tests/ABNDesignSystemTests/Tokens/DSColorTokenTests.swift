import Testing
import UIKit

@testable import ABNDesignSystem

/// Every color pair the components draw meets WCAG 2.2 contrast in light, dark, and both with Increase Contrast.
@Suite("Color contrast")
struct DSColorTokenTests {
    @Test("Each pair meets its WCAG minimum", arguments: ContrastPair.all, Appearance.allCases)
    func meetsMinimum(pair: ContrastPair, appearance: Appearance) async throws {
        let ratio = try pair.ratio(in: await appearance.traits)
        #expect(ratio >= pair.minimum, "\(pair) is \(ratio):1 in \(appearance), needs \(pair.minimum):1")
    }

    @Test("Increase Contrast never lowers a ratio", arguments: ContrastPair.all, [Appearance.light, .dark])
    func increaseContrastIsStronger(pair: ContrastPair, base: Appearance) async throws {
        let increased: Appearance = base == .light ? .lightIncreasedContrast : .darkIncreasedContrast
        let baseRatio = try pair.ratio(in: await base.traits)
        let increasedRatio = try pair.ratio(in: await increased.traits)
        #expect(increasedRatio >= baseRatio)
    }

    @Test(
        "Increase Contrast lifts text to WCAG AAA (7:1)",
        arguments: ContrastPair.all.filter(\.isText), [Appearance.lightIncreasedContrast, .darkIncreasedContrast]
    )
    func increaseContrastReachesAAA(pair: ContrastPair, appearance: Appearance) async throws {
        #expect(try pair.ratio(in: await appearance.traits) >= 7)
    }

    @Test("A token picks the value for each appearance")
    func tokenPicksVariant() async {
        let token = DSColorToken(
            light: "#000001",
            dark: "#000002",
            lightIncreasedContrast: "#000003",
            darkIncreasedContrast: "#000004"
        )
        #expect(token.hex(for: await Appearance.light.traits) == "#000001")
        #expect(token.hex(for: await Appearance.dark.traits) == "#000002")
        #expect(token.hex(for: await Appearance.lightIncreasedContrast.traits) == "#000003")
        #expect(token.hex(for: await Appearance.darkIncreasedContrast.traits) == "#000004")
        #expect(token.hex(for: UITraitCollection()) == "#000001", "Unspecified falls back to light, normal contrast")
    }

    @Test("The contrast math matches WCAG's reference values")
    func wcagReferenceValues() {
        #expect(abs(WCAG.contrastRatio("#000000", "#FFFFFF") - 21) < 0.000_1)
        #expect(abs(WCAG.contrastRatio("#534AB7", "#534AB7") - 1) < 0.000_1)
        // #767676 is the lightest gray that passes 4.5:1 on white; #777777 just fails.
        #expect(WCAG.contrastRatio("#767676", "#FFFFFF") >= 4.5)
        #expect(WCAG.contrastRatio("#777777", "#FFFFFF") < 4.5)
    }
}

// MARK: - Fixtures

/// A text or a border drawn on a background, with the minimum ratio WCAG asks for.
struct ContrastPair: Sendable, CustomTestStringConvertible {
    let foreground: String
    let background: String
    let minimum: Double
    /// Text needs 4.5:1 (AA). A border that shows where a control is needs 3:1 (WCAG 1.4.11).
    let isText: Bool

    var testDescription: String { "\(foreground) on \(background)" }

    /// Every pair a component draws.
    static let all: [ContrastPair] = [
        .text("textPrimary", on: "background"),
        .text("textPrimary", on: "surface", minimum: 7),
        .text("textSecondary", on: "surface"),
        .text("onAccent", on: "accent"),
        .text("accent", on: "surface"),
        .text("danger", on: "surface"),
        // A field's label, helper and error sit on the screen background.
        .text("textSecondary", on: "background"),
        .text("danger", on: "background"),
        // Outlined buttons on the screen, and the banner's message and action on its tint.
        .text("accent", on: "background"),
        .text("textPrimary", on: "accentTint"),
        .text("accent", on: "accentTint"),
        // The border is what shows where an empty field is.
        .boundary("fieldBorder", on: "surface"),
        .boundary("fieldBorder", on: "background"),
    ]

    static func text(_ foreground: String, on background: String, minimum: Double = 4.5) -> ContrastPair {
        ContrastPair(foreground: foreground, background: background, minimum: minimum, isText: true)
    }

    static func boundary(_ foreground: String, on background: String) -> ContrastPair {
        ContrastPair(foreground: foreground, background: background, minimum: 3, isText: false)
    }

    func ratio(in traits: UITraitCollection) throws -> Double {
        let foregroundToken = try #require(Self.tokens[foreground], "Unknown token \(foreground)")
        let backgroundToken = try #require(Self.tokens[background], "Unknown token \(background)")
        return WCAG.contrastRatio(
            foregroundToken.uiColor.resolvedColor(with: traits),
            backgroundToken.uiColor.resolvedColor(with: traits)
        )
    }

    private static let tokens = Dictionary(uniqueKeysWithValues: DSColor.allCases.map { ("\($0)", $0.token) })
}
