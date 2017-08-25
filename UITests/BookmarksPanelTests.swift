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

    private func getAppBookmarkStorage() -> BookmarkBufferStorage? {
        let application = UIApplication.shared
        
        guard let delegate = application.delegate as? TestAppDelegate else {
            XCTFail("Couldn't get app delegate.")
            return nil
        }
        
        let profile = delegate.getProfile(application)
        
        guard let bookmarks = profile.bookmarks as? BookmarkBufferStorage else {
            XCTFail("Couldn't get buffer storage.")
            return nil
        }
        
        return bookmarks
    }
    
    private func createSomeBufferBookmarks() {
        // Set up the buffer.
        let bufferDate = Date.now()
        let changedBufferRecords = [
            BookmarkMirrorItem.folder(BookmarkRoots.ToolbarFolderGUID, modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: nil, title: "Bookmarks Toolbar", description: nil, children: ["aaa", "bbb"]),
            BookmarkMirrorItem.bookmark("aaa", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: nil, title: "AAA", description: nil, URI: "http://getfirefox.com", tags: "[]", keyword: nil),
            BookmarkMirrorItem.livemark("bbb", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: nil, title: "Some Livemark", description: nil, feedURI: "https://www.google.ca", siteURI: "https://www.google.ca") ]
        
        if let bookmarks = getAppBookmarkStorage() {
            XCTAssert(bookmarks.applyRecords(changedBufferRecords).value.isSuccess)
        }
    }

    func testBookmarkPanelBufferOnly() {
        // Insert some data into the buffer. There will be nothing in the mirror, but we can still
        // show Desktop Bookmarks.

        createSomeBufferBookmarks()

        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Desktop Bookmarks")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks Toolbar")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("AAA"))
        .assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Some Livemark"))
            .assert(grey_sufficientlyVisible())
        
        // When we tap the livemark, we load the siteURI.
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Some Livemark")).perform(grey_tap())
        
        // … so we show the truncated URL.
        // Strangely, earlgrey cannot find the label in buddybuild, but passes locally. 
        // Using KIF for this check for now.
        EarlGrey.select(elementWithMatcher: grey_accessibilityValue("https://www.google.ca")).assert(grey_sufficientlyVisible())
    }

    func testRootHasLocalAndBuffer() {
        // Add buffer data, then later in the test verify that the buffer mobile folder is not shown in there anymore.
        createSomeBufferBookmarks()
        
        guard let bookmarks = getAppBookmarkStorage() else {
            return
        }
        
        let changedBufferRecords = [
            BookmarkMirrorItem.bookmark("guid0", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "xyz", description: nil, URI: "http://unused.com", tags: "[]", keyword: nil),
            BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: nil, title: "", description: nil, children: ["guid0"])
        ]
        XCTAssert(bookmarks.applyRecords(changedBufferRecords).value.isSuccess)
        
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).perform(grey_tap())
        
        // is this in the root?
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("xyz")).assert(grey_notNil())
        
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Desktop Bookmarks")).perform(grey_tap())
        // this should be missing, they are shown in the root
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Mobile Bookmarks")).assert(grey_nil())
        
        // Add a local bookmark, and then navigate back to the root view (the navigation will refresh the table).
        let ok = (bookmarks as! MergedSQLiteBookmarks).local.addToMobileBookmarks(URL(string: "http://another-unused")!, title: "123", favicon: nil)
        XCTAssert(ok.value.isSuccess)
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).inRoot(grey_kindOfClass(NSClassFromString("UITableView")!)).perform(grey_tap())
        // is this in the root?
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("123")).assert(grey_notNil())
    }
}
