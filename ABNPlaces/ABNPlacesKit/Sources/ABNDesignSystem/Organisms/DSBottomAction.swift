import SwiftUI

extension View {
    /// Pins a full-width primary button above the bottom edge, the content scrolls behind it.
    /// - On iOS 26 it's a `safeAreaBar`, so content scrolling under it gets the system's edge effect. Before iOS 26
    ///   it's a `safeAreaInset` on the system bar material.
    /// - Like the system's tab bar, it stops growing at `xxxLarge`, so at the accessibility sizes it never covers
    ///   the content.
    public func dsBottomAction<Action: View>(@ViewBuilder _ action: () -> Action) -> some View {
        modifier(DSBottomActionModifier(action: action()))
    }
}

private struct DSBottomActionModifier<Action: View>: ViewModifier {
    let action: Action

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.safeAreaBar(edge: .bottom) { bar }
        } else {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                bar.background(.bar)
            }
        }
    }

    private var bar: some View {
        action
            .buttonStyle(.dsPrimary(fullWidth: true))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityShowsLargeContentViewer()
            .padding(.horizontal, DSSpacing.medium)
            .padding(.vertical, DSSpacing.xSmall)
    }
}

// MARK: - Previews

private struct BottomActionPreview: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DSSpacing.small) {
                    ForEach(1...12, id: \.self) { number in
                        DSCard(
                            symbol: .mapPin,
                            title: Text(verbatim: "Place \(number)"),
                            subtitle: Text(verbatim: "52.3676° N, 4.9041° E")
                        )
                    }
                }
                .padding(DSSpacing.medium)
            }
            .background(DSColor.background)
            .navigationTitle(Text(verbatim: "Places"))
            .dsBottomAction {
                Button {
                } label: {
                    Label {
                        Text(verbatim: "Add custom location")
                    } icon: {
                        Image(.add)
                    }
                }
            }
        }
    }
}

#Preview("Light") {
    BottomActionPreview()
}

#Preview("Dark") {
    BottomActionPreview()
        .preferredColorScheme(.dark)
}

#Preview("AX5") {
    BottomActionPreview()
        .environment(\.dynamicTypeSize, .accessibility5)
}
