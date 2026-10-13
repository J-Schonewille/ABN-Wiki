import SwiftUI

/// A loading placeholder: a real ``DSCard`` under `.redacted(reason: .placeholder)`.
/// Because it's the real card, the layout matches, so little moves when the loading finishes.
/// It doesn't shimmer, so it's fine with Reduce Motion, and VoiceOver skips it.
public struct DSSkeletonCard: View {
    private let titleWidthVariant: Int
    private let trailingSymbol: DSSymbol

    /// - Parameters:
    ///   - titleWidthVariant: Picks one of three title lengths, so a list of placeholders doesn't look mechanical.
    ///   - trailingSymbol: The trailing symbol of the cards it stands in for, so it has their shape.
    public init(titleWidthVariant: Int = 0, trailingSymbol: DSSymbol = .chevron) {
        self.titleWidthVariant = titleWidthVariant
        self.trailingSymbol = trailingSymbol
    }

    public var body: some View {
        DSCard(
            symbol: .mapPin,
            title: Text(verbatim: placeholderTitle),
            subtitle: Text(verbatim: "00.0000° N, 0.0000° E"),
            trailingSymbol: trailingSymbol
        )
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }

    /// for titleWidthVariant, never shown or read out: the card draws them as bars, so only their lengths matter.
    private static let placeholderTitles = ["Placeholder place", "A longer placeholder place", "Short place"]

    private var placeholderTitle: String {
        Self.placeholderTitles[titleWidthVariant.positiveModulo(Self.placeholderTitles.count)]
    }
}

/// A column of ``DSSkeletonCard``s that VoiceOver reads as one element with your label, such as "Loading places".
/// Spaced like a list of cards, so nothing moves when they swap.
public struct DSSkeletonList: View {
    private let count: Int
    private let trailingSymbol: DSSymbol
    private let accessibilityLabel: Text

    public init(count: Int = 5, trailingSymbol: DSSymbol = .chevron, accessibilityLabel: Text) {
        self.count = count
        self.trailingSymbol = trailingSymbol
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        VStack(spacing: DSSpacing.small) {
            ForEach(0..<count, id: \.self) { index in
                DSSkeletonCard(titleWidthVariant: index, trailingSymbol: trailingSymbol)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

// so outise users can use whatever number not just 1-3
nonisolated extension Int {
    fileprivate func positiveModulo(_ divisor: Int) -> Int {
        ((self % divisor) + divisor) % divisor
    }
}

// MARK: - Previews

private struct SkeletonPreview: View {
    var body: some View {
        DSSkeletonList(count: 3, accessibilityLabel: Text(verbatim: "Loading places"))
            .padding(DSSpacing.medium)
            .background(DSColor.background)
    }
}

#Preview("Light") {
    SkeletonPreview()
}

#Preview("Dark") {
    SkeletonPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    ScrollView {
        SkeletonPreview()
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}
