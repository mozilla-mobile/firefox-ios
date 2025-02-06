// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class BookmarkParserTests: XCTestCase {
    func testParsesFolderAndBookmarks_Chrome() async throws {
        let html = BookmarkFixtures.html(.chrome).value

        let importer = try BookmarkParser(html: html)
        let bookmarks = try await importer.parseBookmarks()

        let expectedResult = BookmarkFixtures.debugString(.chrome).value

        XCTAssertEqual(bookmarks.debugDescription, expectedResult)
    }

    func testParsesFolderAndBookmarks_Firefox() async throws {
        let html = BookmarkFixtures.html(.firefox).value

        let importer = try BookmarkParser(html: html)
        let bookmarks = try await importer.parseBookmarks()

        let expectedResult = BookmarkFixtures.debugString(.firefox).value

        XCTAssertEqual(bookmarks.debugDescription, expectedResult)
    }

    func testParsesFolderAndBookmarks_Safari() async throws {
        let html = BookmarkFixtures.html(.safari).value

        let importer = try BookmarkParser(html: html)
        let bookmarks = try await importer.parseBookmarks()

        let expectedResult = BookmarkFixtures.debugString(.safari).value

        XCTAssertEqual(bookmarks.debugDescription, expectedResult)
    }
}
