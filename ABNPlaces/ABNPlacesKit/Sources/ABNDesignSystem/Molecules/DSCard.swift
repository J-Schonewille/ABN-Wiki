import SwiftUI

/// A card with a thumbnail, a title, an optional subtitle and a trailing symbol:
/// - The thumbnail is a map pin ``DSIconTile`` by default. Another one sizes itself, so it can grow with the text.
/// - VoiceOver reads it as one element, "title, subtitle". The trailing symbol is hidden, and so is the default
///   thumbnail; hide another thumbnail yourself.
/// - To make it tappable, wrap it in a `Button` with ``DSCardButtonStyle``,
public struct DSCard<Thumbnail: View>: View {
    private let thumbnail: Thumbnail
    private let title: Text
    private let subtitle: Text?
    private let trailingSymbol: DSSymbol

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.redactionReasons) private var redactionReasons
    @ScaledMetric(relativeTo: .headline) private var spacing = DSSpacing.small

    public init(
        thumbnail: Thumbnail = DSIconTile(symbol: .mapPin),
        title: Text,
        subtitle: Text? = nil,
        trailingSymbol: DSSymbol = .chevron
    ) {
        self.thumbnail = thumbnail
        self.title = title
        self.subtitle = subtitle
        self.trailingSymbol = trailingSymbol
    }

    public var body: some View {
        let layout = DSRowLayout(dynamicTypeSize)
        let isPlaceholder = redactionReasons.contains(.placeholder)
        let stack =
            layout == .horizontal
            ? AnyLayout(HStackLayout(alignment: .center, spacing: spacing))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
        stack {
            thumbnail
            VStack(alignment: .leading, spacing: DSSpacing.xxSmall) {
                title
                    .font(.headline)
                    .foregroundStyle(DSColor.textPrimary)
                    .modifier(SkeletonBar(isActive: isPlaceholder))
                if let subtitle {
                    subtitle
                        .font(.subheadline)
                        .foregroundStyle(DSColor.textSecondary)
                        .modifier(SkeletonBar(isActive: isPlaceholder))
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            if layout.showsTrailingAccessory {
                Image(trailingSymbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isPlaceholder ? DSColor.skeleton : DSColor.textSecondary)
                    .unredacted()
                    .accessibilityHidden(true)
            }
        }
        .padding(DSSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.surface, in: .rect(cornerRadius: DSRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DSRadius.card)
                .strokeBorder(DSColor.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// In a placeholder, draws the text as a bar in ``DSColor/skeleton``.
/// SwiftUI's own placeholder draws the text faintly in its own color, so the skeleton color would never show. The
/// invisible text keeps the bar's size, limited to one line, so it doesn't become a big block at large sizes.
private struct SkeletonBar: ViewModifier {
    let isActive: Bool

    @ScaledMetric(relativeTo: .body) private var verticalInset = 4.0

    func body(content: Content) -> some View {
        content
            .lineLimit(isActive ? 1 : nil)
            .opacity(isActive ? 0 : 1)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DSColor.skeleton)
                    .padding(.vertical, verticalInset)
                    .opacity(isActive ? 1 : 0)
            }
    }
}

// MARK: - Previews

private struct CardPreview: View {
    var body: some View {
        VStack(spacing: DSSpacing.small) {
            Button {
            } label: {
                DSCard(
                    title: Text(verbatim: "Amsterdam"),
                    subtitle: Text(verbatim: "52.3676° N, 4.9041° E")
                )
            }
            .buttonStyle(.dsCard)
            DSCard(
                title: Text(verbatim: "Tierra del Fuego National Park, Ushuaia"),
                subtitle: Text(verbatim: "54.8500° S, 68.5667° W")
            )
        }
        .padding(DSSpacing.medium)
        .background(DSColor.background)
    }
}

#Preview("Light") {
    CardPreview()
}

#Preview("Dark") {
    CardPreview()
        .preferredColorScheme(.dark)
}

#Preview("Skeleton") {
    CardPreview()
        .redacted(reason: .placeholder)
}

#Preview("AX5") {
    CardPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
