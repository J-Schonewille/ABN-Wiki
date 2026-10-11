import SwiftUI

struct ContentView: View {
    
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing: 16) {
            Text("Spike for opening wikipedia")
                .padding()

            Button("Open Amsterdam") {
                if let url = URL(string: "wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam")  {
                    openURL(url)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
