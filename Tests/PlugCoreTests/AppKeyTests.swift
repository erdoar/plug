import Foundation
import XCTest
@testable import PlugCore

final class AppKeyTests: XCTestCase {
    func testHelpersGroupWithTheirApp() {
        XCTAssertEqual(AppKey.forBundleID("com.google.Chrome.helper"), "com.google.Chrome")
        XCTAssertEqual(AppKey.forBundleID("com.google.Chrome.helper.Renderer"), "com.google.Chrome")
        XCTAssertEqual(AppKey.forBundleID("com.microsoft.edgemac.helper"), "com.microsoft.edgemac")
        XCTAssertEqual(AppKey.forBundleID("com.spotify.client.helper"), "com.spotify.client")
        XCTAssertEqual(AppKey.forBundleID("com.tinyspeck.slackmacgap.helper"), "com.tinyspeck.slackmacgap")
        XCTAssertEqual(AppKey.forBundleID("com.example.App.HelperRenderer"), "com.example.App")
    }

    func testAppsStayAsTheyAre() {
        XCTAssertEqual(AppKey.forBundleID("com.spotify.client"), "com.spotify.client")
        XCTAssertEqual(AppKey.forBundleID("com.apple.Music"), "com.apple.Music")
        XCTAssertEqual(AppKey.forBundleID("com.apple.WebKit.GPU"), "com.apple.WebKit.GPU")
        XCTAssertEqual(AppKey.forBundleID("helper.example"), "helper.example", "the domain is never stripped")
        XCTAssertEqual(AppKey.forBundleID("com.helperapps.player"), "com.helperapps.player")
        XCTAssertEqual(AppKey.forBundleID(""), "")
    }
}
