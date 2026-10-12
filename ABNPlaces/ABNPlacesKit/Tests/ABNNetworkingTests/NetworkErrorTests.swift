import Foundation
import Testing

@testable import ABNNetworking

@Suite("Network errors")
struct NetworkErrorTests {
    @Test("A CancellationError is .cancelled")
    func mapsCancellationErrorToCancelled() {
        #expect(NetworkError(CancellationError()) == .cancelled)
    }

    @Test("Any other error is an unknown transport failure")
    func mapsAnyOtherErrorToUnknownTransportFailure() {
        #expect(NetworkError(CocoaError(.fileReadUnknown)) == .transport(code: .unknown))
    }
}
