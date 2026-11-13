// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebDataTransfer

final class BrowserTransferBookmarkTests: XCTestCase {
    func testInit_linkWithoutURL_isRejected() {
        XCTAssertNil(BrowserTransferBookmark(
            sourceIdentifier: "1",
            parentIdentifier: nil,
            isFolder: false,
            title: "Missing",
            url: nil
        ))
    }

    func testInit_folderIgnoresURL() throws {
        let folder = try XCTUnwrap(BrowserTransferBookmark(
            sourceIdentifier: "1",
            parentIdentifier: "root",
            isFolder: true,
            title: "Folder",
            url: URL(string: "https://example.com")
        ))

        XCTAssertEqual(folder.kind, .folder)
        XCTAssertEqual(folder.parentIdentifier, "root")
    }

    func testInit_emptyParentIdentifier_isTopLevel() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let link = try XCTUnwrap(BrowserTransferBookmark(
            sourceIdentifier: "2",
            parentIdentifier: "",
            isFolder: false,
            title: "Example",
            url: url
        ))

        XCTAssertNil(link.parentIdentifier)
        XCTAssertEqual(link.kind, .link(url))
        XCTAssertEqual(link.sourceIdentifier, "2")
    }
}
