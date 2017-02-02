/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
@testable import Storage
import Foundation
import WebKit
import EarlGrey

class BookmarksPanelTests: KIFTestCase {
    
    override func setUp() {
        super.setUp()
		BrowserUtils.dismissFirstRunUI()
	}
	
    override func tearDown() {
        super.tearDown()
		BrowserUtils.resetToAboutHome(tester())
    }
    
    func testBookmarkPanelBufferOnly() {
        // Insert some data into the buffer. There will be nothing in the mirror, but we can still
        // show Desktop Bookmarks.

        let application = UIApplication.shared

        guard let delegate = application.delegate as? TestAppDelegate else {
            XCTFail("Couldn't get app delegate.")
            return
        }

        let profile = delegate.getProfile(application)

        guard let bookmarks = profile.bookmarks as? BookmarkBufferStorage else {
            XCTFail("Couldn't get buffer storage.")
            return
        }

        let record1 = BookmarkMirrorItem.bookmark("aaaaaaaaaaaa", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "AAA", description: "AAA desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let record2 = BookmarkMirrorItem.livemark("bbbbbbbbbbbb", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "Some Livemark", description: nil, feedURI: "http://example.org/feed", siteURI: "http://example.org/news")
        let toolbar = BookmarkMirrorItem.folder("toolbar", modified: Date.now(), hasDupe: false, parentID: "places", parentName: "", title: "Bookmarks Toolbar", description: "Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar", children: ["aaaaaaaaaaaa", "bbbbbbbbbbbb"])
        let recordsA: [BookmarkMirrorItem] = [record1, toolbar, record2]

        XCTAssertTrue(bookmarks.applyRecords(recordsA).value.isSuccess)

        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Bookmarks")).performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Desktop Bookmarks")).performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Bookmarks Toolbar")).performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("AAA"))
        .assertWithMatcher(grey_sufficientlyVisible())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Some Livemark"))
            .assertWithMatcher(grey_sufficientlyVisible())
        
        // When we tap the livemark, we load the siteURI.
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Some Livemark")).performAction(grey_tap())
        
        // … so we show the truncated URL.
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("example.org/news"))
            .assertWithMatcher(grey_sufficientlyVisible())
    }
}
