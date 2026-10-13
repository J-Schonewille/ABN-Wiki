import CoreGraphics

/// Spacing, in points. Padding around content stays fixed, so large text keeps its width.
nonisolated public enum DSSpacing {
    public static let xxSmall: CGFloat = 4
    public static let xSmall: CGFloat = 8
    public static let small: CGFloat = 12
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let xLarge: CGFloat = 32
}

nonisolated public enum DSRadius {
    public static let card: CGFloat = 16
    public static let field: CGFloat = 12
}

nonisolated public enum DSSize {
    /// The smallest tap target in Apple's guidelines. It's well above WCAG's 24 × 24.
    public static let minimumTouchTarget: CGFloat = 44
}
