// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class BookmarkTests: XCTestCase {
    func test_BookmarkSerializer_Parser() async throws {
        let input: [BookmarkItem] = [
            .bookmark("One", "https://example.com/one", .empty),
            .folder("My first folder 😆",
                    [
                        .bookmark("Two &!/{}", "https://example.com/two", .empty),
                        .bookmark("Three ÖÄÜ'*", "https://example.com/three", .empty)
                    ], .empty)
        ]

        let html = try await BookmarkSerializer().serializeBookmarks(input)

        let output = try await BookmarkParser(html: html).parseBookmarks()

        XCTAssertEqual(input, output)
    }
}
