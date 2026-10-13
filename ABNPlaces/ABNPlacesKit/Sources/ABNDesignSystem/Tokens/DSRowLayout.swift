import SwiftUI

/// The one rule for large text: at the accessibility sizes, rows stack.
/// Up to `.xxxLarge` an icon, text and a chevron fit side by side. At the five accessibility sizes the text needs
/// the full width, so the row becomes a column and the chevron goes. Components use this instead of deciding
/// themselves, so the rule is tested once.
nonisolated enum DSRowLayout: Equatable, Sendable {
    case horizontal
    case vertical

    init(_ dynamicTypeSize: DynamicTypeSize) {
        self = dynamicTypeSize.isAccessibilitySize ? .vertical : .horizontal
    }

    /// Whether a decorative trailing symbol, such as a chevron, is shown.
    var showsTrailingAccessory: Bool {
        self == .horizontal
    }
}

// MARK: - Previews

/// A sample row at one text size: side by side with a chevron, or stacked without one.
private struct RowLayoutPreview: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = DSRowLayout(dynamicTypeSize)
        let stack =
            layout == .horizontal
            ? AnyLayout(HStackLayout(spacing: DSSpacing.small))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: DSSpacing.small))
        stack {
            Image(.mapPin)
                .foregroundStyle(DSColor.accent)
                .accessibilityHidden(true)
            Text(verbatim: "\(dynamicTypeSize)")
                .foregroundStyle(DSColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if layout.showsTrailingAccessory {
                Image(.chevron)
                    .foregroundStyle(DSColor.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(DSSpacing.small)
        .background(DSColor.surface, in: .rect(cornerRadius: DSRadius.card))
    }
}

// The row at all 12 text sizes: it stacks from accessibility1 on.
#Preview("All text sizes") {
    ScrollView {
        VStack(spacing: DSSpacing.small) {
            ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                RowLayoutPreview()
                    .environment(\.dynamicTypeSize, size)
            }
        }
        .padding(DSSpacing.medium)
    }
    .background(DSColor.background)
}
