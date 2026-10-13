import UIKit

/// The four looks a color has: light and dark, each with and without Increase Contrast.
enum Appearance: String, CaseIterable, Sendable {
    case light
    case dark
    case lightIncreasedContrast
    case darkIncreasedContrast

    /// UIKit builds trait collections on the main actor. Reading colors with them doesn't need it.
    @MainActor var traits: UITraitCollection {
        UITraitCollection { traits in
            traits.userInterfaceStyle = self == .dark || self == .darkIncreasedContrast ? .dark : .light
            traits.accessibilityContrast = self == .light || self == .dark ? .normal : .high
        }
    }
}
