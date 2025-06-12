// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerMobileNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(MobileBookmarks) { screenState in
        let bookmarksMenuNavigationBar = app.navigationBars["Mobile Bookmarks"]
        let bookmarksButton = bookmarksMenuNavigationBar.buttons["Bookmarks"]
        screenState.gesture(
            forAction: Action.ExitMobileBookmarksFolder,
            transitionTo: LibraryPanel_Bookmarks
        ) { userState in
                bookmarksButton.waitAndTap()
        }
        screenState.tap(app.buttons["Edit"], to: MobileBookmarksEdit)
    }

    map.addScreenState(MobileBookmarksEdit) { screenState in
        screenState.tap(app.buttons["libraryPanelBottomLeftButton"], to: MobileBookmarksAdd)
        screenState.gesture(forAction: Action.RemoveItemMobileBookmarks) { userState in
            app.tables["Bookmarks List"].buttons.element(boundBy: 0).waitAndTap()
        }
        screenState.gesture(forAction: Action.ConfirmRemoveItemMobileBookmarks) { userState in
            app.buttons["Delete"].waitAndTap()
        }
    }

    map.addScreenState(MobileBookmarksAdd) { screenState in
        screenState.gesture(forAction: Action.AddNewBookmark, transitionTo: EnterNewBookmarkTitleAndUrl) { userState in
            app.otherElements["New Bookmark"].waitAndTap()
        }
        screenState.gesture(forAction: Action.AddNewFolder) { userState in
            app.otherElements["New Folder"].waitAndTap()
        }
        screenState.gesture(forAction: Action.AddNewSeparator) { userState in
            app.otherElements["New Separator"].waitAndTap()
        }
    }
}
