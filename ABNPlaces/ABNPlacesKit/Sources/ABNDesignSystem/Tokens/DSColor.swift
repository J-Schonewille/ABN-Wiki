import SwiftUI

/// The colors views use, by role. Each one follows the appearance and the contrast setting by itself, so views never
/// check them. A `ShapeStyle`, so it goes wherever SwiftUI takes a color: `.foregroundStyle(DSColor.textPrimary)`.
nonisolated public enum DSColor: CaseIterable, Sendable, ShapeStyle {
    case background
    case surface
    case separator
    case fieldBorder
    case textPrimary
    case textSecondary
    case accent
    case onAccent
    case accentTint
    case danger
    case skeleton

    /// Its four looks. A new case doesn't compile until it has its token.
    var token: DSColorToken {
        switch self {
        case .background: .background
        case .surface: .surface
        case .separator: .separator
        case .fieldBorder: .fieldBorder
        case .textPrimary: .textPrimary
        case .textSecondary: .textSecondary
        case .accent: .accent
        case .onAccent: .onAccent
        case .accentTint: .accentTint
        case .danger: .danger
        case .skeleton: .skeleton
        }
    }

    public func resolve(in environment: EnvironmentValues) -> Color {
        Color(uiColor: token.uiColor)
    }
}

// MARK: - Previews

/// Every color as the app draws it, in the canvas's color scheme. The palette preview in `DSColorToken.swift` shows
/// all four looks at once.
private struct ColorsPreview: View {
    var body: some View {
        List(DSColor.allCases, id: \.self) { color in
            HStack(spacing: DSSpacing.small) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6).strokeBorder(.gray.opacity(0.4))
                    }
                    .frame(width: 44, height: 32)
                Text(verbatim: "\(color)")
            }
        }
    }
}

#Preview("Light") {
    ColorsPreview()
}

#Preview("Dark") {
    ColorsPreview()
        .preferredColorScheme(.dark)
}
