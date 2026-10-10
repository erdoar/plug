import XCTest
@testable import PlugCore

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

final class EffectIDTests: XCTestCase {
    func testBuildsFromFourCharacterCodes() {
        let id = EffectID(type: "aufx", subtype: "dely", manufacturer: "appl")
        XCTAssertEqual(id?.type, 0x6175_6678)
        XCTAssertEqual(id?.subtype, 0x6465_6C79)
        XCTAssertEqual(id?.manufacturer, 0x6170_706C)
    }

    func testRejectsCodesThatAreNotFourASCIICharacters() {
        XCTAssertNil(EffectID(type: "auf", subtype: "dely", manufacturer: "appl"))
        XCTAssertNil(EffectID(type: "aufx", subtype: "delay", manufacturer: "appl"))
        XCTAssertNil(EffectID(type: "aufx", subtype: "dely", manufacturer: "äppl"))
    }

    func testIndexOfSlot() {
        var chain = PluginChain()
        let a = PluginSlot(name: "A")
        let b = PluginSlot(name: "B")
        chain.append(a)
        chain.append(b)
        XCTAssertEqual(chain.index(of: b.id), 1)
        XCTAssertNil(chain.index(of: UUID()))
    }
}
