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

    private func chain(_ names: [String]) -> PluginChain {
        var chain = PluginChain()
        names.forEach { chain.append(PluginSlot(name: $0)) }
        return chain
    }

    func testMoveOffsetsUpAndDown() {
        var down = chain(["A", "B", "C", "D"])
        down.move(fromOffsets: [0], toOffset: 3)
        XCTAssertEqual(down.slots.map(\.name), ["B", "C", "A", "D"])

        var up = chain(["A", "B", "C", "D"])
        up.move(fromOffsets: [3], toOffset: 0)
        XCTAssertEqual(up.slots.map(\.name), ["D", "A", "B", "C"])
    }

    func testMoveSeveralKeepsTheirOrder() {
        var several = chain(["A", "B", "C", "D"])
        several.move(fromOffsets: [0, 2], toOffset: 4)
        XCTAssertEqual(several.slots.map(\.name), ["B", "D", "A", "C"])
    }

    func testMoveOntoItselfOrOutOfRangeChangesNothing() {
        var same = chain(["A", "B", "C"])
        same.move(fromOffsets: [1], toOffset: 1)
        same.move(fromOffsets: [1], toOffset: 2)
        same.move(fromOffsets: [7], toOffset: 0)
        same.move(fromOffsets: [0], toOffset: 9)
        XCTAssertEqual(same.slots.map(\.name), ["A", "B", "C"])
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
