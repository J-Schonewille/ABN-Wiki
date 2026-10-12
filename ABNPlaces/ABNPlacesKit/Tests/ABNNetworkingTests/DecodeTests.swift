import ABNNetworking
import Foundation
import Testing

@Suite("Decoding")
struct DecodeTests {
    struct Greeting: Decodable, Equatable, Sendable {
        let text: String
        let count: Int
    }

    @Test("Valid JSON decodes into the type")
    func decodesValidJSON() async throws {
        let data = Data(#"{"text":"hello","count":2}"#.utf8)

        let greeting = try await decode(Greeting.self, from: data)

        #expect(greeting == Greeting(text: "hello", count: 2))
    }

    @Test(
        "A body that isn't the expected JSON throws .decoding",
        arguments: [
            "",
            "not json",
            #"{"text":"hello"}"#,
            #"{"text":"hello","count":"two"}"#,
            #"[{"text":"hello","count":2}]"#,
        ]
    )
    func throwsDecodingForUnexpectedBody(_ body: String) async {
        await #expect(throws: NetworkError.decoding) {
            try await decode(Greeting.self, from: Data(body.utf8))
        }
    }

    /// Remembers whether `init(from:)` ran on the main thread.
    struct ThreadProbe: Decodable, Sendable {
        let decodedOnMainThread: Bool

        init(from decoder: any Decoder) {
            decodedOnMainThread = Thread.isMainThread
        }
    }

    @MainActor
    @Test("Decoding runs off the main actor, also when it's called from there")
    func decodesOffTheMainActorEvenWhenCalledFromIt() async throws {
        let probe = try await decode(ThreadProbe.self, from: Data("{}".utf8))

        #expect(probe.decodedOnMainThread == false)
    }
}
