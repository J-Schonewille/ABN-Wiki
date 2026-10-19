import ABNDesignSystem
import SwiftUI

/// A card inside a `Button`, like a screen uses it. The subtitle is read as words ("degrees north").
struct CardButton: View {
    let title: String
    let coordinates: String
    let spokenCoordinates: String

    var body: some View {
        Button {
        } label: {
            DSCard(
                title: Text(verbatim: title),
                subtitle: Text(verbatim: coordinates).accessibilityLabel(Text(verbatim: spokenCoordinates))
            )
        }
        .buttonStyle(.dsCard)
        .accessibilityHint(Text(verbatim: "Opens the details"))
    }
}
