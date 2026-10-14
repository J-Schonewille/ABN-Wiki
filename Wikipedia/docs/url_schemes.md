# URL schemes

The URL scheme is `wikipedia://`. The following URLs are currently handled:

| Feature            | Format                                   | Example                                  |
| ------------------ | ---------------------------------------- | ---------------------------------------- |
| Article            | wikipedia://[site]/wiki/[page_id]        | wikipedia://en.wikipedia.org/wiki/Red    |
|                    | https://[[site]/wiki/[page_id]           | https://en.wikipedia.org/wiki/Red        |
| Content            | wikipedia://content                      | wikipedia://content/on-this-day/wikipedia.org/en/2024/08/15                                         |
| Explore            | wikipedia://explore                      |                                          |
| History            | wikipedia://history                      |                                          |
| Places             | wikipedia://places[?WMFArticleURL=]      | wikipedia://places/?WMFArticleURL=https://en.wikipedia.org/wiki/Dallas |
| Places location    | wikipedia://places?lat=&lon=[&name=]     | wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam |
| Saved pages        | wikipedia://saved                        |                                          |

## Places location

`wikipedia://places?lat=<latitude>&lon=<longitude>[&name=<name>]` opens Places on the map, centred on the location with a span of about 10 km, and puts a pin on it.

| Parameter       | Rule |
| --------------- | ---- |
| `lat`           | Required. Decimal degrees matching `-?[0-9]{1,3}(\.[0-9]{1,15})?`, from -90 to 90. A `.` as the decimal separator; no exponent or `+`. |
| `lon`           | Required. Same format, from -180 to 180. |
| `name`          | Optional pin title, percent-encoded UTF-8; a `+` stays a plus. Control and format characters are removed, and the rest is NFC-normalised, trimmed and cut to 100 characters. |
| `WMFArticleURL` | A full `https` article URL. When present, the location is ignored: Places shows the article if it's on the device, and otherwise opens as usual. |

- Keys are lowercase. The first of a repeated key wins, an empty value counts as missing, and other keys are ignored.
- `wikipedia-official://` and `places/` work too.
- A missing or invalid location opens Places as usual.
- Places only loads the articles around the location when it has no results yet, or when the location is far from them. A link that arrives while a search is running loads no new articles.
- The pin stays until a link to another location replaces it, or a new search removes it: one the user starts (text, a search result, "Your location") or a Places link that shows an article. "All top articles" and "All saved articles" keep it.
- The map centres at most 84.5° north or south. MapKit draws no pin beyond 85°.
- After a link, the first GPS fix doesn't move the map. With VoiceOver on, Places stays in the list.
- Don't send `source`: the app uses it to attribute app opens.

Senders: build the URL with `URLComponents`, and write the numbers with the POSIX locale, such as `degrees.formatted(.number.locale(Locale(identifier: "en_US_POSIX")).precision(.fractionLength(0...7)))`. `String(describing:)` (`1e-07`) and a user-locale formatter (`52,35`) don't match the grammar.

To try it: `xcrun simctl openurl booted "wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam"`
