import ABNDesignSystem
import Testing
import UIKit

@Suite("SF Symbols")
struct DSSymbolTests {
    @Test("Every symbol exists in SF Symbols", arguments: DSSymbol.allCases)
    func symbolExists(_ symbol: DSSymbol) {
        #expect(UIImage(systemName: symbol.rawValue) != nil, "No SF Symbol called \(symbol.rawValue)")
    }
}
