import SwiftUI
import Testing

@testable import ABNPlacesFeature

@MainActor
@Suite("CreatePlaceView snapshots")
struct CreatePlaceViewTests {
    @Test("Empty: each field is one element, read by its label")
    func empty() {
        let sheet = Self.sheet(CreatePlaceModel())

        assertScreenSnapshot(of: sheet, named: "create-place", state: "empty")
        assertScreenAccessibilitySnapshot(of: sheet, named: "create-place", state: "empty")
    }

    @Test("Errors after a save: each error under its field, and part of the field's label")
    func errors() {
        let model = CreatePlaceModel()
        model.name = "Home"
        model.latitude = "91"
        model.longitude = ""
        _ = model.save()
        let sheet = Self.sheet(model)

        assertScreenSnapshot(of: sheet, named: "create-place", state: "errors")
        assertScreenAccessibilitySnapshot(of: sheet, named: "create-place", state: "errors")
    }

    private static func sheet(_ model: CreatePlaceModel) -> some View {
        NavigationStack {
            CreatePlaceView(model: model)
        }
    }
}
