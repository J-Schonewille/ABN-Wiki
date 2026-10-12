import Foundation

public extension NSUserActivity {
    @objc var shouldSkipOnboarding: Bool {
        guard let path = webpageURL?.wikiResourcePath,
              let languageCode = webpageURL?.wmf_languageCode else {
            return false
        }

        let namespaceAndTitle = path.namespaceAndTitleOfWikiResourcePath(with: languageCode)
        let namespace = namespaceAndTitle.0
        let title = namespaceAndTitle.1

        return namespace == .special && title == "ReadingLists"
    }

    /// Turns `wikipedia://places?lat=…&lon=…` into a `PlacesLocationRequest`.
    /// The default places logic has priority, so if the link has a link URL, this is nil.
    var wmf_placesLocationRequest: PlacesLocationRequest? {
        guard wmf_type() == .places,
              wmf_linkURL() == nil,
              let url = userInfo?[WMFPlacesURLUserInfoKey] as? URL else {
            return nil
        }
        return PlacesLocationRequest(url: url)
    }
}
