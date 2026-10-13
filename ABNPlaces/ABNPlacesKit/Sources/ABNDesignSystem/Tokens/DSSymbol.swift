import SwiftUI

/// Every SF Symbol the app shows. Names are typed once, here, and `DSSymbolTests` checks that each one exists.
nonisolated public enum DSSymbol: String, CaseIterable, Sendable {
    /// A place on the map.
    case mapPin = "mappin.and.ellipse"
    /// No places.
    case noMapPin = "mappin.slash"
    /// A tap opens another app, such as Wikipedia.
    case openInOtherApp = "arrow.up.forward"
    /// A tap goes deeper inside the app.
    case chevron = "chevron.forward"
    /// No internet connection.
    case offline = "wifi.slash"
    /// The server failed.
    case serverError = "exclamationmark.icloud"
    /// Something unexpected went wrong.
    case warning = "exclamationmark.triangle"
    /// A message that needs attention.
    case notice = "exclamationmark.circle"
    /// An error in a field.
    case fieldError = "exclamationmark.circle.fill"
    /// Add something.
    case add = "plus"
    case refresh = "arrow.clockwise"
}

extension Image {
    /// The SF Symbol for `symbol`.
    public init(_ symbol: DSSymbol) {
        self.init(systemName: symbol.rawValue)
    }
}

// MARK: - Previews

/// Every symbol with its case name and its SF Symbols name.
private struct SymbolsPreview: View {
    var body: some View {
        List(DSSymbol.allCases, id: \.self) { symbol in
            Label {
                VStack(alignment: .leading) {
                    Text(verbatim: "\(symbol)")
                        .foregroundStyle(DSColor.textPrimary)
                    Text(verbatim: symbol.rawValue)
                        .font(.caption.monospaced())
                        .foregroundStyle(DSColor.textSecondary)
                }
            } icon: {
                Image(symbol)
                    .foregroundStyle(DSColor.accent)
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview("All symbols") {
    SymbolsPreview()
}

#Preview("Dark") {
    SymbolsPreview()
        .preferredColorScheme(.dark)
}
