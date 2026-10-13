import SwiftUI

struct CreatePlaceSheet: View {
    @State private var model = CreatePlaceModel()

    var body: some View {
        NavigationStack {
            CreatePlaceView(model: model)
        }
        .presentationSizing(.form)
    }
}
