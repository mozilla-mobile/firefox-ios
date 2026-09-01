// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CoreSpotlight
import XCTest

@testable import Client

@available(iOS 18.0, *)
final class BrowserEntityTests: XCTestCase {
    private let url = URL(string: "https://www.mozilla.org/firefox/")!

    /// The on-device model can only select the open tabs through a text match, so both forms of the word have to be
    /// part of the indexed text of every tab.
    func test_attributeSet_forTab_indexesTypeAsSearchableText() {
        let attributeSet = createSubject(type: .tab).attributeSet

        XCTAssertEqual(attributeSet.kind, "Open Tab")
        XCTAssertEqual(attributeSet.keywords?.contains("tab"), true)
        XCTAssertEqual(attributeSet.keywords?.contains("tabs"), true)
        XCTAssertEqual(attributeSet.contentDescription?.contains("Open Tab"), true)
    }

    func test_attributeSet_forBookmark_indexesTypeAsSearchableText() {
        let attributeSet = createSubject(type: .bookmark).attributeSet

        XCTAssertEqual(attributeSet.kind, "Bookmark")
        XCTAssertEqual(attributeSet.keywords?.contains("bookmark"), true)
        XCTAssertEqual(attributeSet.keywords?.contains("bookmarks"), true)
        XCTAssertEqual(attributeSet.contentDescription?.contains("Bookmark"), true)
    }

    func test_attributeSet_carriesTitleAndContentURL() {
        let attributeSet = createSubject(type: .tab).attributeSet

        XCTAssertEqual(attributeSet.title, "Mozilla")
        XCTAssertEqual(attributeSet.contentURL, url)
        XCTAssertEqual(attributeSet.contentDescription?.contains(url.absoluteDisplayString), true)
    }

    func test_attributeSet_forTab_doesNotUseBookmarkKeywords() {
        let attributeSet = createSubject(type: .tab).attributeSet

        XCTAssertEqual(attributeSet.keywords?.contains("bookmark"), false)
    }

    private func createSubject(type: BrowserEntityType) -> BrowserEntity {
        return BrowserEntity(id: BrowserEntityID(type: type, url: url),
                             title: "Mozilla",
                             lastUsedDate: nil)
    }
}
