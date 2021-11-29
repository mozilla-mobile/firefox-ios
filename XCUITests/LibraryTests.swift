// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class LibraryTestsIpad: IpadOnlyTestCase {

    func testLibraryShortcut() {
        if skipPlatform {return}
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 3)
        navigator.performAction(Action.CloseURLBarOpen)
        // Open Library from shortcut
        waitForExistence(app.buttons["TabToolbar.libraryButton"])
        let libraryShorcutButton = app.buttons["TabToolbar.libraryButton"]
        libraryShorcutButton.tap()
        navigator.nowAt(HomePanel_Library)
        waitForExistence(app.tables["Bookmarks List"])
        // Go to a different panel, like History
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables["History List"])
    }
}

class LibraryTestsIphone: IphoneOnlyTestCase {
    
    func testLibraryShortcutHomePage () {
        if skipPlatform {return}
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForExistence(app.staticTexts[AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.library], timeout: 3)
        waitForExistence(app.buttons["menu Bookmark"])
        waitForExistence(app.buttons["menu panel ReadingList"])
        waitForExistence(app.buttons["menu panel Downloads"])
        
        // Check if clicking on Bookmark option shows bookmarks
        app.buttons["menu Bookmark"].tap()
        navigator.nowAt(LibraryPanel_Bookmarks)
        waitForExistence(app.tables["Bookmarks List"])
        navigator.goto(HomePanelsScreen)

        // Check if clicking on Reading List option shows reading list
        app.buttons["menu panel ReadingList"].tap()
        navigator.nowAt(LibraryPanel_ReadingList)
        waitForExistence(app.tables["ReadingTable"])
        navigator.goto(HomePanelsScreen)
        
        // Check if clicking on Downloads option shows downloads
        app.buttons["menu panel Downloads"].tap()
        navigator.nowAt(LibraryPanel_Downloads)
        waitForExistence(app.tables["DownloadsTable"])
        navigator.goto(HomePanelsScreen)
    }
}
