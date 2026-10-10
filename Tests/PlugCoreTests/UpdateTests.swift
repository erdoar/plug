import Foundation
import XCTest
@testable import PlugCore

final class UpdateTests: XCTestCase {
    func testVersionsParseAndCompare() throws {
        XCTAssertEqual(AppVersion("v1.2"), AppVersion("1.2.0"))
        XCTAssertLessThan(try XCTUnwrap(AppVersion("1.9")), try XCTUnwrap(AppVersion("1.10")))
        XCTAssertLessThan(try XCTUnwrap(AppVersion("0.1.0")), try XCTUnwrap(AppVersion("v0.2")))
        XCTAssertEqual(AppVersion("V2.0.1")?.description, "2.0.1")
        XCTAssertNil(AppVersion("beta"))
        XCTAssertNil(AppVersion("1.2.3-beta"))
        XCTAssertNil(AppVersion(""))
        XCTAssertNil(AppVersion("1..2"))
    }

    func testReadsGitHubsReply() throws {
        let json = #"{"tag_name":"v0.3.0","html_url":"https://github.com/erdoar/plug/releases/tag/v0.3.0","draft":false,"name":"Plug 0.3"}"#
        let release = try JSONDecoder().decode(GitHubRelease.self, from: Data(json.utf8))
        XCTAssertEqual(release, GitHubRelease(tagName: "v0.3.0", pageURL: "https://github.com/erdoar/plug/releases/tag/v0.3.0"))
    }

    func testEvaluate() throws {
        let release = GitHubRelease(tagName: "v0.3.0", pageURL: "page")
        XCTAssertEqual(UpdateCheck.evaluate(currentVersion: "0.2.5", latest: release),
                       .newer(try XCTUnwrap(AppVersion("0.3.0")), pageURL: "page", current: try XCTUnwrap(AppVersion("0.2.5"))))
        XCTAssertEqual(UpdateCheck.evaluate(currentVersion: "0.3", latest: release),
                       .upToDate(try XCTUnwrap(AppVersion("0.3"))))
        XCTAssertEqual(UpdateCheck.evaluate(currentVersion: "1.0", latest: release),
                       .upToDate(try XCTUnwrap(AppVersion("1.0"))), "a newer local build counts as up to date")
        XCTAssertEqual(UpdateCheck.evaluate(currentVersion: "0.1.0", latest: nil), .noReleases)
        XCTAssertEqual(UpdateCheck.evaluate(currentVersion: nil, latest: release), .cannotCompare)
        XCTAssertEqual(UpdateCheck.evaluate(currentVersion: "0.1", latest: GitHubRelease(tagName: "nightly", pageURL: "p")), .cannotCompare)
    }
}
