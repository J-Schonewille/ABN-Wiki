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

`wikipedia://places?lat=<latitude>&lon=<longitude>[&name=<label>]` opens the Places tab on the map, puts a pin on the location, centres the map on it with a span of about 10 km, and lists the top articles around it.

| Parameter       | Rule |
| --------------- | ---- |
| `lat`           | Required. Decimal degrees matching `-?[0-9]{1,3}(\.[0-9]{1,15})?`: an optional minus, a `.` as the decimal separator and at most 15 fraction digits. No exponent, hex, `+`, whitespace, `nan` or `inf`. From -90 to 90, inclusive. |
| `lon`           | Required. Same format, from -180 to 180, inclusive. |
| `name`          | Optional label, percent-encoded UTF-8. A `+` is a literal plus, not a space. Control and format characters, such as bidi overrides and zero-width characters, are removed; the rest is NFC-normalised, trimmed and cut to 100 grapheme clusters. It is the pin's title, shown under the pin when there is room, and what VoiceOver reads for it. Without a name, the pin has no title and VoiceOver reads MapKit's "Map pin". |
| `WMFArticleURL` | When present, Places shows that article as before and ignores `lat`, `lon` and `name`. |

- Keys are lowercase and case-sensitive. For a repeated key, the first value is used. An empty value counts as missing. Other parameters are ignored.
- `wikipedia-official://` works too, and so does a trailing slash (`places/`).
- When the location is missing or invalid, Places opens as it does without parameters.
- The pin stays while the user pans, zooms, reloads the articles with "Results in this area" or switches to the list and back. A link to another location replaces it. Searching Places for something else, or a link that opens an article, removes it; a link without a valid location leaves it.
- MapKit's map stops at 85° north and south, so the map is centred at most 84.5° from the equator, where the usual span still fits. A latitude beyond that, up to a pole, is still valid: the map then centres at ±84.5°, and the pin, which keeps the real latitude, lies north or south of the view. MapKit doesn't draw a pin beyond ±85° at all, so a link to a pole shows no pin.
- After such a link, the user's own location doesn't move the map when the first GPS fix arrives. The "recenter on my location" button still does.
- With VoiceOver running, the link doesn't switch Places from the list to the map. Places starts in the list under VoiceOver, and the list shows the same articles; the pin is on the map when the user switches to it.
- Senders should build the URL with `URLComponents` and `URLQueryItem`, and write numbers in fixed notation with the POSIX locale and at most 15 fraction digits, for example with `degrees.formatted(.number.locale(Locale(identifier: "en_US_POSIX")).precision(.fractionLength(0...7)))`. That writes `52.3547498` and `0.0000001`; 7 fraction digits are about 1 cm. Don't use `String(describing:)`, which writes `1e-07` and `0.30000000000000004`, or a user-locale `NumberFormatter`, which writes `52,35` in Dutch: the grammar rejects all three.
- Don't send `source`. The app reserves it for attributing app opens, and a link that carries it is no longer treated as an external link.

Examples:

- `wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam`
- `wikipedia://places?lat=40.4380638&lon=-3.7495758`

To try one on a booted simulator: `xcrun simctl openurl booted "wikipedia://places?lat=19.0823998&lon=72.8111468&name=Mumbai"`
