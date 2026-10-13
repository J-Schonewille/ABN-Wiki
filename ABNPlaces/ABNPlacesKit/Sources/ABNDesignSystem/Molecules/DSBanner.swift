import SwiftUI

/// A banner with one action, such as "Couldn't refresh · Retry".
/// - VoiceOver reads two elements: the message, then the action.
public struct DSBanner<Action: View>: View {
    private let message: Text
    private let symbol: DSSymbol
    private let action: Action

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameter action: Gets ``DSButtonStyle/dsSecondary`` unless you style it.
    public init(_ message: Text, symbol: DSSymbol = .notice, @ViewBuilder action: () -> Action) {
        self.message = message
        self.symbol = symbol
        self.action = action()
    }

    public var body: some View {
        let layout = DSRowLayout(dynamicTypeSize)
        let stack =
            layout == .horizontal
            ? AnyLayout(HStackLayout(alignment: .center, spacing: DSSpacing.small))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: DSSpacing.small))
        stack {
            Label {
                message
                    .foregroundStyle(DSColor.textPrimary)
            } icon: {
                Image(symbol)
                    .foregroundStyle(DSColor.accent)
                    .accessibilityHidden(true)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            action
                .buttonStyle(.dsSecondary(fullWidth: layout == .vertical))
        }
        .padding(DSSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.accentTint, in: .rect(cornerRadius: DSRadius.card))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

private struct BannerPreview: View {
    var body: some View {
        DSBanner(Text(verbatim: "Couldn't refresh. Showing earlier results.")) {
            Button {
            } label: {
                Text(verbatim: "Retry")
            }
        }
        .padding(DSSpacing.medium)
        .background(DSColor.background)
    }
}

#Preview("Light") {
    BannerPreview()
}

#Preview("Dark") {
    BannerPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    BannerPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
