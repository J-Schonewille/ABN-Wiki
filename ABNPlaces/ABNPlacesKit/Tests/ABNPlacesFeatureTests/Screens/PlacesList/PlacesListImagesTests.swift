import ABNPlacesCore
import Dependencies
import Foundation
import Testing

@testable import ABNPlacesFeature

@MainActor
@Suite("Places list: the cards' images")
struct PlacesListImagesTests {
    @Test("A card's image is looked up by the place's name and coordinate, once")
    func looksUpAnImageOncePerPlace() async {
        let searched = LockIsolated<[String]>([])
        let model = Self.model(images: Self.recording(into: searched))

        await model.loadImage(for: .amsterdam)
        await model.loadImage(for: .amsterdam)

        #expect(model.imageURLs == [Place.amsterdam.id: .placeStubImage])
        #expect(searched.value == ["Amsterdam at 52.3547498, 4.8339215"])
    }

    @Test("A place without a name isn't looked up")
    func skipsAnUnnamedPlace() async {
        let searched = LockIsolated<[String]>([])
        let model = Self.model(images: Self.recording(into: searched))

        await model.loadImage(for: .unnamedMadrid)

        #expect(model.imageURLs.isEmpty)
        #expect(searched.value.isEmpty)
    }

    @Test(
        "Without an image, the card keeps its map pin tile",
        arguments: [ImagesAPIError.noResult, .offline, .server, .cancelled]
    )
    func keepsTheTileWithoutAnImage(_ error: ImagesAPIError) async {
        let model = Self.model(images: .failing(error))

        await model.loadImage(for: .amsterdam)

        #expect(model.imageURLs.isEmpty)
    }

    @Test("A lookup that failed is tried again the next time, and then shows the image")
    func triesAFailedLookupAgain() async {
        let searches = LockIsolated(0)
        let model = Self.model(
            images: ImagesAPI { (_: String, _: Coordinate) async throws(ImagesAPIError) in
                let search = searches.withValue { count in
                    count += 1
                    return count
                }
                guard search > 1 else { throw .offline }
                return .placeStubImage
            })

        await model.loadImage(for: .amsterdam)
        #expect(model.imageURLs.isEmpty)
        await model.loadImage(for: .amsterdam)

        #expect(model.imageURLs == [Place.amsterdam.id: .placeStubImage])
    }

    /// The cards' lookups restart when it changes, which retries the images that failed while offline.
    @Test("Each load that works is counted, and a failed one isn't")
    func countsTheLoadsThatWork() async {
        let fetches = LockIsolated(0)
        let model = withDependencies {
            $0.imagesAPI = .empty
            $0.placesAPI = PlacesAPI { () throws(PlacesAPIError) in
                let fetch = fetches.withValue { count in
                    count += 1
                    return count
                }
                guard fetch != 2 else { throw .offline }
                return .preview
            }
        } operation: {
            PlacesListModel()
        }

        await model.loadIfNeeded()
        #expect(model.completedLoadCount == 1)
        await model.refresh()
        #expect(model.completedLoadCount == 1)
        await model.refresh()
        #expect(model.completedLoadCount == 2)
    }

    // MARK: Helpers

    /// Made inside `withDependencies`, because `@Dependency` reads its values when the model is created.
    private static func model(images: ImagesAPI) -> PlacesListModel {
        withDependencies {
            $0.imagesAPI = images
        } operation: {
            PlacesListModel()
        }
    }

    /// Finds the stub photo for every place, and writes down what it was asked.
    private static func recording(into searched: LockIsolated<[String]>) -> ImagesAPI {
        ImagesAPI { (name: String, coordinate: Coordinate) async throws(ImagesAPIError) in
            searched.withValue { $0.append("\(name) at \(coordinate.latitude), \(coordinate.longitude)") }
            return .placeStubImage
        }
    }
}
