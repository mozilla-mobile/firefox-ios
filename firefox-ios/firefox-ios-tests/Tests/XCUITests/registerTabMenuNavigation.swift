// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerTabMenuNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(ToolsBrowserTabMenu) { screenState in
        // Zoom
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.zoom],
            to: PageZoom)
        // Turn on night mode
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.nightMode],
            forAction: Action.ToggleNightMode,
            transitionTo: BrowserTab
        ) { userState in
            userState.nightMode = !userState.nightMode
        }
        // Report broken site (TODO)
        // Share
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.share],
            forAction: Action.ShareBrowserTabMenuOption
        ) { userState in
        }

        screenState.dismissOnUse = true
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(SaveBrowserTabMenu) { screenState in
        // Bookmark this page
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.bookmarkThisPage],
            forAction: Action.BookmarkThreeDots
        )
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.bookmarkThisPage],
            forAction: Action.Bookmark
        )
        // Add to shortcuts
        // No Copy link available (Action.CopyAddressPAM)
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.addToShortcuts],
            forAction: Action.PinToTopSitesPAM
        )
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.saveToReadingList],
            forAction: Action.AddToReadingListBrowserTabMenu
        )

        screenState.dismissOnUse = true
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(BrowserTabMenu) { screenState in
        sleep(1)

        // Sign In (if unauthenticated)
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.MainMenu.HeaderView.mainButton],
            to: Intro_FxASignin,
            if: "fxaUsername == nil")
        // Signed in (TODO)
        // New tab
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.newTab], to: NewTabScreen)
        // New private tab (TODO: Action.OpenPrivateTabLongPressTabsButton
        // Switch to Desktop/Mobile Site
        // The cell's identifier is the same for desktop and mobile, so I use static
        // texts for the RequestMobileSite case
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.switchToDesktopSite], to: RequestDesktopSite)
        screenState.tap(app.tables.cells.staticTexts["Switch to Mobile Site"], to: RequestMobileSite)
        // Find in Page...
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.findInPage],
            to: FindInPage)
        // Tools (Zoom, NightMode, Report, Share)
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.tools], to: ToolsBrowserTabMenu)
        // Save (Add Bookmark, Shortcut)
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.save], to: SaveBrowserTabMenu)
        // Bookmarks
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.bookmarks], to: LibraryPanel_Bookmarks)
        // History
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.history],
            to: LibraryPanel_History)
        // Downloads
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.downloads],
            to: LibraryPanel_Downloads
        )
        // Passwords (TODO)
        // Customize Homepage (TODO)
        // New in Firefox
        screenState.tap(
            app.otherElements.cells["MainMenu.WhatsNew"],
            forAction: Action.OpenWhatsNewPage
        )
        // Get Help (TODO: Actions to open support.mozilla.org)
        // SettingsScreen
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.settings], to: SettingsScreen)

        // "x" for close the menu and go back
        screenState.dismissOnUse = true
        screenState.backAction = cancelBackAction(for: app)
    }

    map.addScreenState(CloseTabMenu) { screenState in
        screenState.tap(
            app.scrollViews.buttons[AccessibilityIdentifiers.TabTray.deleteCloseAllButton],
            forAction: Action.AcceptRemovingAllTabs,
            transitionTo: HomePanelsScreen
        )
        screenState.backAction = cancelBackAction(for: app)
    }
}
