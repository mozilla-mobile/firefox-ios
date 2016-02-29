/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
@testable import Storage
import Foundation
import WebKit

class BookmarksPanelTests: KIFTestCase {
    func testBookmarkPanelBufferOnly() {
        // Insert some data into the buffer. There will be nothing in the mirror, but we can still
        // show Desktop Bookmarks.

        let application = UIApplication.sharedApplication()

        guard let delegate = application.delegate as? TestAppDelegate else {
            XCTFail("Couldn't get app delegate.")
            return
        }

        let profile = delegate.getProfile(application)

        guard let bookmarks = profile.bookmarks as? BookmarkBufferStorage else {
            XCTFail("Couldn't get buffer storage.")
            return
        }

        let record1 = BookmarkMirrorItem.bookmark("aaaaaaaaaaaa", modified: NSDate.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "AAA", description: "AAA desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let record2 = BookmarkMirrorItem.livemark("bbbbbbbbbbbb", modified: NSDate.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "Some Livemark", description: nil, feedURI: "http://example.org/feed", siteURI: "http://example.org/news")
        let toolbar = BookmarkMirrorItem.folder("toolbar", modified: NSDate.now(), hasDupe: false, parentID: "places", parentName: "", title: "Bookmarks Toolbar", description: "Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar", children: ["aaaaaaaaaaaa", "bbbbbbbbbbbb"])
        let recordsA: [BookmarkMirrorItem] = [record1, toolbar, record2]

        XCTAssertTrue(bookmarks.applyRecords(recordsA).value.isSuccess)

        tester().tapViewWithAccessibilityLabel("Bookmarks")
        tester().tapViewWithAccessibilityLabel("Desktop Bookmarks")
        tester().tapViewWithAccessibilityLabel("Bookmarks Toolbar")
        tester().waitForViewWithAccessibilityLabel("AAA")
        tester().waitForViewWithAccessibilityLabel("Some Livemark")

        // When we tap the livemark, we load the siteURI.
        tester().tapViewWithAccessibilityLabel("Some Livemark")

        // … so we show the truncated URL.
        tester().waitForViewWithAccessibilityLabel("example.org/news")
    }
}