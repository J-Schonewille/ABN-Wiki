import ABNPlacesCore
import Testing

@Suite("Coordinate input parser")
struct CoordinateInputParserTests {
    // MARK: Accepted

    @Test(
        "Accepts a latitude written the Dutch or the English way",
        arguments: [
            ("52,3547", 52.3547),  // Dutch decimal comma
            ("52.3547", 52.3547),  // English decimal point
            ("-3.75", -3.75),
            ("-3,75", -3.75),
            ("\u{2212}3.75", -3.75),  // typographic minus, U+2212
            ("\u{2212}3,75", -3.75),
            ("  52,3547 ", 52.3547),
            ("\t52.3547\n", 52.3547),
            ("90", 90),
            ("-90", -90),
            ("0", 0),
            ("007,5", 7.5),
        ] as [(String, Double)]
    )
    func acceptsLatitude(text: String, expected: Double) throws {
        #expect(try CoordinateInputParser.latitude(from: text) == expected)
    }

    @Test(
        "Accepts a longitude written the Dutch or the English way",
        arguments: [
            ("4,8339215", 4.8339215),
            ("4.8339215", 4.8339215),
            ("\u{2212}3,7495758", -3.7495758),
            ("180", 180),
            ("-180", -180),
            ("120.5", 120.5),  // valid longitude, out of range as latitude
        ] as [(String, Double)]
    )
    func acceptsLongitude(text: String, expected: Double) throws {
        #expect(try CoordinateInputParser.longitude(from: text) == expected)
    }

    // MARK: Rejected

    static let notANumberTexts = [
        "1.234,5",  // Dutch grouping
        "1,234.5",  // English grouping
        "52.35.47",  // several separators
        "52,35,47",
        "5e1",  // exponent
        "5.235E1",
        "0x1p3",  // hex
        "0x34",
        "nan",
        "NaN",
        "inf",
        "-infinity",
        "52.3a",  // letters
        "N52",
        "abc",
        "+52.3",
        ".5",
        "5.",
        "-",
        "--5",
        "52 35",
        "\u{0665}\u{0662}",  // Arabic-Indic digits
    ]

    @Test("Rejects blank text as empty", arguments: ["", "   ", "\t\n"])
    func rejectsEmptyText(_ text: String) {
        #expect(throws: CoordinateInputError.empty) { try CoordinateInputParser.latitude(from: text) }
        #expect(throws: CoordinateInputError.empty) { try CoordinateInputParser.longitude(from: text) }
    }

    @Test("Rejects text that isn't a plain decimal number", arguments: notANumberTexts)
    func rejectsTextThatIsNotAPlainNumber(_ text: String) {
        #expect(throws: CoordinateInputError.notANumber) { try CoordinateInputParser.latitude(from: text) }
        #expect(throws: CoordinateInputError.notANumber) { try CoordinateInputParser.longitude(from: text) }
    }

    @Test(
        "Rejects a latitude outside −90...90",
        arguments: ["90,0000001", "-90.5", "120.5", "1" + String(repeating: "0", count: 400)]
    )
    func rejectsLatitudeOutOfRange(_ text: String) {
        #expect(throws: CoordinateInputError.outOfRange(-90...90)) {
            try CoordinateInputParser.latitude(from: text)
        }
    }

    @Test("Rejects a longitude outside −180...180", arguments: ["180,0000001", "-180.5", "200"])
    func rejectsLongitudeOutOfRange(_ text: String) {
        #expect(throws: CoordinateInputError.outOfRange(-180...180)) {
            try CoordinateInputParser.longitude(from: text)
        }
    }
}
