import XCTest
@testable import Plug

final class PluginChainTests: XCTestCase {
    func testAppendAndRemove() {
        var chain = PluginChain()
        chain.append(PluginSlot(name: "A"))
        chain.append(PluginSlot(name: "B"))
        chain.remove(at: 0)
        XCTAssertEqual(chain.slots.map(\.name), ["B"])
    }

    func testMoveToEnd() {
        var chain = PluginChain()
        ["A", "B", "C"].forEach { chain.append(PluginSlot(name: $0)) }
        chain.move(from: 0, to: 3)
        XCTAssertEqual(chain.slots.map(\.name), ["B", "C", "A"])
    }

    func testBypassIsPerSlot() {
        var chain = PluginChain()
        chain.append(PluginSlot(name: "A"))
        chain.append(PluginSlot(name: "B"))
        chain.setBypassed(true, at: 1)
        XCTAssertEqual(chain.slots.map(\.isBypassed), [false, true])
    }

    func testOutOfRangeIsIgnored() {
        var chain = PluginChain()
        chain.append(PluginSlot(name: "A"))
        chain.remove(at: 5)
        chain.setBypassed(true, at: 5)
        XCTAssertEqual(chain.slots.count, 1)
        XCTAssertFalse(chain.slots[0].isBypassed)
    }
}
