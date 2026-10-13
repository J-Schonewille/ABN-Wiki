import SwiftUI

/// - Labels wrap instead of being cut off, so they stay whole up to AX5.
/// - Pressed and disabled buttons dim. Nothing moves, so it's fine with Reduce Motion.
public struct DSButtonStyle: ButtonStyle {
    nonisolated enum Prominence: Sendable {
        case primary
        case secondary
    }

    private let prominence: Prominence
    private let isFullWidth: Bool

    init(_ prominence: Prominence, fullWidth: Bool = false) {
        self.prominence = prominence
        self.isFullWidth = fullWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        DSButtonLabel(configuration: configuration, prominence: prominence, isFullWidth: isFullWidth)
    }
}

extension ButtonStyle where Self == DSButtonStyle {
    /// A purple fill, as wide as its label.
    public static var dsPrimary: DSButtonStyle { DSButtonStyle(.primary) }

    /// A purple outline, as wide as its label.
    public static var dsSecondary: DSButtonStyle { DSButtonStyle(.secondary) }

    /// A purple fill, optionally as wide as its container.
    public static func dsPrimary(fullWidth: Bool) -> DSButtonStyle {
        DSButtonStyle(.primary, fullWidth: fullWidth)
    }

    /// A purple outline, optionally as wide as its container.
    public static func dsSecondary(fullWidth: Bool) -> DSButtonStyle {
        DSButtonStyle(.secondary, fullWidth: fullWidth)
    }
}

/// A view, so it can read the environment and @ScaledMetric
private struct DSButtonLabel: View {
    let configuration: ButtonStyleConfiguration
    let prominence: DSButtonStyle.Prominence
    let isFullWidth: Bool

    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric(relativeTo: .headline) private var verticalPadding = DSSpacing.small
    /// Just over half the height of a one-line button at every text size, so one line stays a capsule.
    @ScaledMetric(relativeTo: .headline) private var maxCornerRadius = 26.0

    var body: some View {
        let shape = DSButtonShape(maxCornerRadius: max(maxCornerRadius, DSSize.minimumTouchTarget / 2))
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, DSSpacing.large)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: DSSize.minimumTouchTarget)
            .foregroundStyle(prominence == .primary ? DSColor.onAccent : DSColor.accent)
            .background {
                if prominence == .primary {
                    shape.fill(DSColor.accent)
                }
            }
            .overlay {
                if prominence == .secondary {
                    shape.strokeBorder(DSColor.accent, lineWidth: 1.5)
                }
            }
            .contentShape(shape)
            .opacity(opacity)
    }

    private static let disabledOpacity = 0.4
    private static let pressedOpacity = 0.7

    private var opacity: Double {
        guard isEnabled else { return Self.disabledOpacity }
        return configuration.isPressed ? Self.pressedOpacity : 1
    }
}

nonisolated struct DSButtonShape: InsettableShape {
    var maxCornerRadius: CGFloat
    var insetAmount: CGFloat = 0

    static func cornerRadius(height: CGFloat, maxCornerRadius: CGFloat) -> CGFloat {
        min(height / 2, maxCornerRadius)
    }

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = Self.cornerRadius(height: insetRect.height, maxCornerRadius: max(0, maxCornerRadius - insetAmount))
        return Path(roundedRect: insetRect, cornerRadius: radius, style: .circular)
    }

    func inset(by amount: CGFloat) -> DSButtonShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

// MARK: - Previews

private struct ButtonPreview: View {
    var body: some View {
        VStack(spacing: DSSpacing.medium) {
            Button {
            } label: {
                Text(verbatim: "Add custom location")
            }
            .buttonStyle(.dsPrimary(fullWidth: true))
            Button {
            } label: {
                Text(verbatim: "Try again")
            }
            .buttonStyle(.dsSecondary)
            Button {
            } label: {
                Text(verbatim: "Open")
            }
            .buttonStyle(.dsPrimary)
            .disabled(true)
        }
        .padding(DSSpacing.medium)
        .background(DSColor.background)
    }
}

#Preview("Light") {
    ButtonPreview()
}

#Preview("Dark") {
    ButtonPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    ButtonPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
