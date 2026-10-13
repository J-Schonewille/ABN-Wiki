import SwiftUI

/// The button style for a ``DSCard``.
/// The `Button` gives VoiceOver the button trait, makes the card work with a keyboard and Switch Control.
public struct DSCardButtonStyle: ButtonStyle {

    private static let pressedTintOpacity = 0.12

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: DSRadius.card)
        configuration.label
            .overlay {
                shape
                    .fill(DSColor.accent.opacity(configuration.isPressed ? Self.pressedTintOpacity : 0))
                    .allowsHitTesting(false)
            }
            .contentShape(shape)
            .contentShape(.hoverEffect, shape)
            .hoverEffect(.highlight)
    }
}

extension ButtonStyle where Self == DSCardButtonStyle {
    public static var dsCard: DSCardButtonStyle { DSCardButtonStyle() }
}

// MARK: - Previews

private struct CardButtonPreview: View {
    var body: some View {
        VStack(spacing: DSSpacing.small) {
            Button {
            } label: {
                DSCard(
                    symbol: .mapPin,
                    title: Text(verbatim: "Amsterdam"),
                    subtitle: Text(verbatim: "52.3676° N, 4.9041° E"),
                    trailingSymbol: .openInOtherApp
                )
            }
            Button {
            } label: {
                DSCard(
                    symbol: .mapPin,
                    title: Text(verbatim: "Tierra del Fuego National Park, Ushuaia"),
                    subtitle: Text(verbatim: "54.8500° S, 68.5667° W")
                )
            }
        }
        .buttonStyle(.dsCard)
        .padding(DSSpacing.medium)
        .background(DSColor.background)
    }
}

#Preview("Light") {
    CardButtonPreview()
}

#Preview("Dark") {
    CardButtonPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    CardButtonPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
