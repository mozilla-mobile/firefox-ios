// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerLibraryPanelNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    let doneButton = app.buttons["Done"]

    map.addScreenState(LibraryPanel_ReadingList) { screenState in
        screenState.dismissOnUse = true
        screenState.gesture(forAction: Action.CloseReadingListPanel, transitionTo: HomePanelsScreen) { userState in
            doneButton.waitAndTap()
        }
    }

    map.addScreenState(LibraryPanel_Downloads) { screenState in
        let readingListButton = app.buttons["readingListLarge"]

        screenState.dismissOnUse = true
        screenState.gesture(forAction: Action.CloseDownloadsPanel, transitionTo: HomePanelsScreen) { userState in
            doneButton.waitAndTap()
        }
        screenState.tap(readingListButton, to: LibraryPanel_ReadingList)
    }

    map.addScreenState(LibraryPanel_History) { screenState in
        screenState.press(
            app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView].cells.element(boundBy: 2),
            to: HistoryPanelContextMenu
        )
        screenState.tap(
            app.cells[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.recentlyClosedCell],
            to: HistoryRecentlyClosed
        )
        screenState.gesture(forAction: Action.ClearRecentHistory) { userState in
            app.toolbars.matching(identifier: "Toolbar").buttons["historyBottomDeleteButton"].waitAndTap()
        }
        screenState.gesture(forAction: Action.CloseHistoryListPanel, transitionTo: HomePanelsScreen) { userState in
            doneButton.waitAndTap()
        }
    }

    map.addScreenState(LibraryPanel_Bookmarks) { screenState in
        let mobileBookmarksCell = app.cells.staticTexts["Mobile Bookmarks"]
        let bookmarksTable = app.tables["Bookmarks List"]

        screenState.tap(mobileBookmarksCell, to: MobileBookmarks)
        screenState.gesture(forAction: Action.CloseBookmarkPanel, transitionTo: HomePanelsScreen) { userState in
            doneButton.waitAndTap()
        }

        screenState.press(bookmarksTable.cells.element(boundBy: 4), to: BookmarksPanelContextMenu)
    }
}
