/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class LibraryTestsIpad: IpadOnlyTestCase {

    func testLibraryShortcut() {
        if Base.helper.skipPlatform {return}
        // Open Library from shortcut
        Base.helper.waitForExistence(Base.app.buttons["TabToolbar.libraryButton"])
        let libraryShorcutButton = Base.app.buttons["TabToolbar.libraryButton"]
        libraryShorcutButton.tap()
        navigator.nowAt(HomePanel_Library)
        Base.helper.waitForExistence(Base.app.tables["Bookmarks List"])
        // Go to a different panel, like History
        navigator.goto(LibraryPanel_History)
        // Verify that next time Library opens in last visited panel
        navigator.goto(HomePanelsScreen)
        Base.helper.waitForExistence(Base.app.buttons["TabToolbar.libraryButton"])
        libraryShorcutButton.tap()
        Base.helper.waitForExistence(Base.app.tables["History List"])
    }
}

class LibraryTestsIphone: IphoneOnlyTestCase {
    
    func testLibraryShortcutHomePage () {
        if Base.helper.skipPlatform {return}
        Base.helper.waitForExistence(Base.app.staticTexts["libraryTitle"])
        Base.helper.waitForExistence(Base.app.buttons["menu Bookmark"])
        Base.helper.waitForExistence(Base.app.buttons["menu panel ReadingList"])
        Base.helper.waitForExistence(Base.app.buttons["menu panel Downloads"])
        Base.helper.waitForExistence(Base.app.buttons["menu sync"])
        Base.helper.waitForExistence(Base.app.buttons["libraryMoreButton"])
        
        // Check if clicking on Bookmark option shows bookmarks
        Base.app.buttons["menu Bookmark"].tap()
        navigator.nowAt(LibraryPanel_Bookmarks)
        Base.helper.waitForExistence(Base.app.tables["Bookmarks List"])
        navigator.goto(HomePanelsScreen)
        
        // Check if clicking on Reading List option shows reading list
        Base.app.buttons["menu panel ReadingList"].tap()
        navigator.nowAt(LibraryPanel_ReadingList)
        Base.helper.waitForExistence(Base.app.tables["ReadingTable"])
        navigator.goto(HomePanelsScreen)
        
        // Check if clicking on Downloads option shows downloads
        Base.app.buttons["menu panel Downloads"].tap()
        navigator.nowAt(LibraryPanel_Downloads)
        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])
        navigator.goto(HomePanelsScreen)

         // Check if clicking on Synced Tabs option shows synced tabs
        Base.app.buttons["menu sync"].tap()
        navigator.nowAt(LibraryPanel_SyncedTabs)
        Base.helper.waitForExistence(Base.app.tables["Synced Tabs"])
        navigator.goto(HomePanelsScreen)

        // Check if clicking on the See All option shows history
        Base.app.buttons["libraryMoreButton"].tap()
        navigator.nowAt(LibraryPanel_History)
        Base.helper.waitForExistence(Base.app.tables["History List"])
        navigator.goto(HomePanelsScreen)
    }
}
