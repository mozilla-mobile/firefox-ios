// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class BookmarkSerializerTests: XCTestCase {
    func test_SerializesBookmarks() async throws {
        let bookmarks: [BookmarkItem] = [
            .folder(
                "Favorites",
                [
                    .bookmark(
                        "One",
                        "https://example.com/one",
                        .empty
                    ),
                    .bookmark(
                        "Two",
                        "https://example.com/two",
                        .empty
                    ),
                    .folder(
                        "My Folder #1",
                        [
                            .bookmark(
                                "Three",
                                "https://example.com/three",
                                .init(
                                    addedAt: .init(timeIntervalSince1970: 123),
                                    modifiedAt: nil
                                )
                            )
                        ],
                        .empty
                    ),
                    .folder(
                        "My Folder #2",
                        [
                            .bookmark(
                                "Four",
                                "https://example.com/four",
                                .init(
                                    addedAt: .init(timeIntervalSince1970: 456),
                                    modifiedAt: nil
                                )
                            ),
                            .folder(
                                "My Subfolder #1",
                                [
                                    .bookmark(
                                        "Five",
                                        "https://example.com/five",
                                        .init(
                                            addedAt: .init(timeIntervalSince1970: 789),
                                            modifiedAt: .init(timeIntervalSince1970: 987)
                                        )
                                    )
                                ],
                                .empty
                            )
                        ],
                        .empty
                    )
                ],
                .empty
            )
        ]

        let html = try await BookmarkSerializer()
            .serializeBookmarks(bookmarks)
            .filter { !$0.isWhitespace }

        XCTAssertEqual(
            html,
            BookmarkFixtures.ecosiaExportedHtml.filter { !$0.isWhitespace }
        )
    }
}
