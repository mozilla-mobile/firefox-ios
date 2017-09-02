/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
@testable import Storage
import Shared
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

    private func navigateBackInTableView() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).inRoot(grey_kindOfClass(NSClassFromString("UITableView")!)).perform(grey_tap())
    }
    
    private func navigateFolder(withTitle title: String) {
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel(title)).perform(grey_tap())
    }

    private func makeBookmark(guid: GUID, parentID: GUID, title: String) -> BookmarkMirrorItem {
        return BookmarkMirrorItem.bookmark(guid, modified: Date.now(), hasDupe: false, parentID: parentID, parentName: nil, title: title, description: nil, URI: "http://unused.com", tags: "[]", keyword: nil)
    }
    
    private func makeFolder(guid: GUID, parentID: GUID, title: String, childrenGuids: [GUID]) -> BookmarkMirrorItem {
        return BookmarkMirrorItem.folder(guid, modified: Date.now(), hasDupe: false, parentID: parentID, parentName: nil, title: title, description: nil, children: childrenGuids)
    }
    
    private func assertRowExists(withTitle title: String) {
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel(title)).inRoot(grey_kindOfClass(NSClassFromString("UITableView")!)).assert(grey_notNil())
    }
    
    func testRootHasLocalAndBuffer() {
        // Add buffer data, then later in the test verify that the buffer mobile folder is not shown in there anymore.
        createSomeBufferBookmarks()
        
        guard let bookmarks = getAppBookmarkStorage() else {
            return
        }
        
        // TEST: Create remote mobile bookmark, and verify the bookmark appears in the root and the remote mobile folder is not shown
        var applyResult = bookmarks.applyRecords([
            makeBookmark(guid: "bm-guid0", parentID: BookmarkRoots.MobileFolderGUID, title: "xyz"),
            makeFolder(guid: BookmarkRoots.MobileFolderGUID, parentID: BookmarkRoots.RootGUID, title: "", childrenGuids: ["bm-guid0"])
            ])
        XCTAssert(applyResult.value.isSuccess)
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).perform(grey_tap())
        
        // is this in the root?
        assertRowExists(withTitle: "xyz")
        
        navigateFolder(withTitle: "Desktop Bookmarks")
        // this should be missing, they are shown in the root
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Mobile Bookmarks")).assert(grey_nil())
        
        // TEST: Add a local bookmark, and then navigate back to the root view (the navigation will refresh the table).
        let isAdded = (bookmarks as! MergedSQLiteBookmarks).local.addToMobileBookmarks(URL(string: "http://another-unused")!, title: "123", favicon: nil)
        XCTAssert(isAdded.value.isSuccess)
        navigateBackInTableView()
        // is this in the root?
        assertRowExists(withTitle: "123")
        
        // TEST: Add sub-folder to MobileFolderGUID, ensure it is navigable
        applyResult = bookmarks.applyRecords([
            makeBookmark(guid: "bm-guid1", parentID: "folder-guid0", title: "item-in-remote-subfolder"),
            makeFolder(guid: "folder-guid0", parentID: BookmarkRoots.MobileFolderGUID, title: "remote-subfolder", childrenGuids: ["bm-guid1"]),
            makeFolder(guid: BookmarkRoots.MobileFolderGUID, parentID: BookmarkRoots.RootGUID, title: "", childrenGuids: ["bm-guid0", "folder-guid0"])
            ])
        XCTAssert(applyResult.value.isSuccess)
        
        // refresh view
        navigateFolder(withTitle: "Desktop Bookmarks")
        navigateBackInTableView()
        
        // subfolder should now be in the root
        assertRowExists(withTitle: "remote-subfolder")
        
        // navigate remote mobile subfolder, ensure bookmark is shown in the subfolder
        navigateFolder(withTitle: "remote-subfolder")
        assertRowExists(withTitle: "item-in-remote-subfolder")
    }
}
