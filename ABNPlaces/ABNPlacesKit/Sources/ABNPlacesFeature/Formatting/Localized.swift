import Foundation

/// A string from this module's string catalog, in `locale`'s language.
/// Views show copy with `Text("…", bundle: #bundle)`. Some copy is needed as a `String`, such as coordinates for
/// VoiceOver or an announcement. This uses the view's `@Environment(\.locale)`, so a screen, its previews and its
/// snapshot tests stay in one language.
/// When the catalog doesn't have that language, it falls back to the language iOS picked for this module, which is
/// also the one `Text` shows. Someone with French first and Dutch second then gets Dutch everywhere.
nonisolated func localized(_ value: String.LocalizationValue, locale: Locale, comment: StaticString? = nil) -> String {
    let resource = LocalizedStringResource(value, locale: lookupLocale(for: locale), bundle: #bundle, comment: comment)
    return String(localized: resource)
}

nonisolated private func lookupLocale(for locale: Locale) -> Locale {
    let bundle = #bundle
    guard let language = locale.language.languageCode?.identifier,
        !bundle.localizations.contains(language),
        let negotiated = bundle.preferredLocalizations.first
    else {
        return locale
    }
    return Locale(identifier: negotiated)
}
