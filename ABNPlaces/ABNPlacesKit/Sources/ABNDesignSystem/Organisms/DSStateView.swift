import SwiftUI

/// A card for empty and error states: an icon in a circle, a title, a message and actions.
/// - VoiceOver skips the icon. The title is a heading, so VoiceOver users can jump to it. Then the message, then
///   each action.
/// - Actions get ``DSButtonStyle/dsSecondary`` unless you style them.
/// - Used instead of `ContentUnavailableView`, so empty and error states look like the rest of the design system.
public struct DSStateView<Actions: View>: View {
    private let symbol: DSSymbol
    private let title: Text
    private let message: Text
    private let actions: Actions

    public init(symbol: DSSymbol, title: Text, message: Text, @ViewBuilder actions: () -> Actions) {
        self.symbol = symbol
        self.title = title
        self.message = message
        self.actions = actions()
    }

    public var body: some View {
        VStack(spacing: DSSpacing.medium) {
            DSIconTile(symbol: symbol, style: .circle)
            VStack(spacing: DSSpacing.xSmall) {
                title
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DSColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                message
                    .font(.body)
                    .foregroundStyle(DSColor.textSecondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            actions
                .buttonStyle(.dsSecondary)
        }
        .padding(DSSpacing.large)
        .frame(maxWidth: .infinity)
        .background(DSColor.surface, in: .rect(cornerRadius: DSRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DSRadius.card)
                .strokeBorder(DSColor.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

extension DSStateView where Actions == EmptyView {
    public init(symbol: DSSymbol, title: Text, message: Text) {
        self.init(symbol: symbol, title: title, message: message) { EmptyView() }
    }
}

// MARK: - Previews

private struct StateViewPreview: View {
    var body: some View {
        VStack(spacing: DSSpacing.medium) {
            DSStateView(
                symbol: .offline,
                title: Text(verbatim: "Couldn't load places"),
                message: Text(verbatim: "Check your connection and try again.")
            ) {
                Button {
                } label: {
                    Text(verbatim: "Try again")
                }
            }
            DSStateView(
                symbol: .noMapPin,
                title: Text(verbatim: "No places yet"),
                message: Text(verbatim: "There are no places to show.")
            )
        }
        .padding(DSSpacing.medium)
        .background(DSColor.background)
    }
}

#Preview("Light") {
    StateViewPreview()
}

#Preview("Dark") {
    StateViewPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    ScrollView {
        StateViewPreview()
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}
