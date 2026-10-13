import ABNDesignSystem
import ABNPlacesCore
import Foundation

nonisolated enum LoadFailure: Equatable, Sendable {
    case offline
    case server
    case unexpectedData

    init?(_ error: LocationsError) {
        switch error {
        case .cancelled:
            return nil
        case .offline:
            self = .offline
        case .server:
            self = .server
        case .unexpectedData:
            self = .unexpectedData
        }
    }
}

// MARK: - Copy

nonisolated extension LoadFailure {

    var symbol: DSSymbol {
        switch self {
        case .offline: .offline
        case .server: .serverError
        case .unexpectedData: .warning
        }
    }

    func title(in locale: Locale) -> String {
        switch self {
        case .offline:
            localized("Can't connect", locale: locale, comment: "Title when the device can't reach the server.")
        case .server:
            localized("Couldn't load places", locale: locale, comment: "Title when the server failed.")
        case .unexpectedData:
            localized("Couldn't read places", locale: locale, comment: "Title when the server sent unreadable data.")
        }
    }

    /// What happened, and what to do about it.
    func message(in locale: Locale) -> String {
        switch self {
        case .offline:
            localized(
                "Check your internet connection to load places.",
                locale: locale,
                comment: "Message under “Can't connect”."
            )
        case .server:
            localized(
                "Something went wrong on the server. Try again in a moment.",
                locale: locale,
                comment: "Message under “Couldn't load places”."
            )
        case .unexpectedData:
            localized(
                "The server sent something this app doesn't understand. Try again later.",
                locale: locale,
                comment: "Message under “Couldn't read places”."
            )
        }
    }

    func loadAnnouncement(in locale: Locale) -> String {
        localized(
            "\(title(in: locale)). \(message(in: locale))",
            locale: locale,
            comment: "Announced by VoiceOver when places couldn't load: a title, then a message, both written out."
        )
    }
}
