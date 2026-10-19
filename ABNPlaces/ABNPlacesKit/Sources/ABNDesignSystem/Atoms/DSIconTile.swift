import SwiftUI

/// An SF Symbol in purple on a light purple rounded square (`.tile`) or circle (`.circle`).
/// - Hidden from VoiceOver by default. Pass `accessibilityLabel` only when the icon itself means something.
/// - Grows with the text up to `.xxxLarge`, then stops, so at the accessibility sizes the room goes to the text.
/// - Inside `.redacted(reason: .placeholder)` it becomes a plain placeholder shape.
public struct DSIconTile: View {
    nonisolated public enum Style: Sendable {
        /// A 44 pt rounded square, for cards and rows.
        case tile
        /// A 64 pt circle, for empty and error states.
        case circle
    }

    private let symbol: DSSymbol
    private let style: Style
    private let accessibilityLabel: Text?

    public init(symbol: DSSymbol, style: Style = .tile, accessibilityLabel: Text? = nil) {
        self.symbol = symbol
        self.style = style
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        DSIconTileContent(symbol: symbol, style: style)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel ?? Text(verbatim: ""))
            .accessibilityAddTraits(.isImage)
            .accessibilityHidden(accessibilityLabel == nil)
    }
}

/// The `.tile` rounded square at any size. The corner grows with the side, so the shape stays the same.
/// Clip an image to it to match ``DSIconTile``.
nonisolated public struct DSTileShape: Shape {
    /// The tile at the default text size.
    static let baseSide = 44.0
    static let baseCornerRadius = 12.0

    public init() {}

    public func path(in rect: CGRect) -> Path {
        RoundedRectangle(cornerRadius: rect.width * Self.baseCornerRadius / Self.baseSide, style: .continuous)
            .path(in: rect)
    }
}

/// Separate from ``DSIconTile``, so its `@ScaledMetric`s see the capped text size.
private struct DSIconTileContent: View {
    let symbol: DSSymbol
    let style: DSIconTile.Style

    @Environment(\.redactionReasons) private var redactionReasons
    @ScaledMetric(relativeTo: .title3) private var tileSide = DSTileShape.baseSide
    @ScaledMetric(relativeTo: .title) private var circleDiameter = 64.0

    var body: some View {
        let isPlaceholder = redactionReasons.contains(.placeholder)
        let side = style == .tile ? tileSide : circleDiameter
        // The circle needs circular corners; smooth ones would flatten it.
        let shape =
            style == .tile
            ? AnyShape(DSTileShape())
            : AnyShape(RoundedRectangle(cornerRadius: side / 2, style: .circular))
        Image(symbol)
            .font(style == .tile ? .title3.weight(.semibold) : .title.weight(.semibold))
            .foregroundStyle(DSColor.accent)
            .opacity(isPlaceholder ? 0 : 1)
            .accessibilityHidden(true)
            .frame(width: side, height: side)
            .background(isPlaceholder ? DSColor.skeleton : DSColor.accentTint, in: shape)
    }
}

// MARK: - Previews

private struct IconTilePreview: View {
    var body: some View {
        HStack(spacing: DSSpacing.medium) {
            DSIconTile(symbol: .mapPin)
            DSIconTile(symbol: .offline, style: .circle)
        }
        .padding(DSSpacing.medium)
        .background(DSColor.surface)
    }
}

#Preview("Light") {
    IconTilePreview()
}

#Preview("Dark") {
    IconTilePreview()
        .preferredColorScheme(.dark)
}

#Preview("Skeleton") {
    IconTilePreview()
        .redacted(reason: .placeholder)
}

#Preview("AX5") {
    IconTilePreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
