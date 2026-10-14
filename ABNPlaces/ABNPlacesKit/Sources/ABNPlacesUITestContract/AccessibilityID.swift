/// Shared by the screens and the UI tests, so a rename breaks the build, not a test. Users never see or hear them.
public enum AccessibilityID {
    public enum PlacesList {
        public static let refresh = "placesList.refresh"
        /// The first load's error and its Retry button.
        public static let loadFailure = "placesList.loadFailure"
        public static let retry = "placesList.retry"
        public static let addPlace = "placesList.addPlace"

        /// A place's card, by `Place.id`.
        public static func card(id: String) -> String {
            "placesList.card.\(id)"
        }
    }

    public enum CreatePlace {
        public static let name = "createPlace.name"
        public static let latitude = "createPlace.latitude"
        public static let longitude = "createPlace.longitude"
        public static let save = "createPlace.save"
        public static let cancel = "createPlace.cancel"
    }
}
