// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

@MainActor
func registerTabMenuNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(BrowserTabMenuMore) { screenState in
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.zoom],
            to: PageZoom)
        // Add To Shortcuts
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.addToShortcuts],
            forAction: Action.PinToTopSitesPAM)
        // Web Site Dark Mode
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.nightMode],
            forAction: Action.ToggleNightMode)
        // Save As PDF (TODO)
        // Print
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.print],
            to: PrintPage)
        // Turn on night mode
        screenState.dismissOnUse = true
        screenState.backAction = cancelBackAction(for: app)
    }

    map.addScreenState(BrowserTabMenu) { screenState in
        sleep(1)
        // Bookmarks
        screenState.tap(app.tables.cells.buttons[AccessibilityIdentifiers.MainMenu.bookmarks], to: LibraryPanel_Bookmarks)
        // History
        screenState.tap(
            app.tables.cells.buttons[AccessibilityIdentifiers.MainMenu.history],
            to: LibraryPanel_History)
        // Downloads
        screenState.tap(
            app.tables.cells.buttons[AccessibilityIdentifiers.MainMenu.downloads],
            to: LibraryPanel_Downloads
        )
        // More Options
        screenState.tap(
            app.tables.cells["MainMenu.MoreLess"],
            to: BrowserTabMenuMore)
        // Tracking Protections (TODO)

        // Find In Page
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.findInPage],
            to: FindInPage)
        // Desktop Site
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.desktopSite],
            to: RequestDesktopSite
        )
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.desktopSite],
                        to: RequestMobileSite)

        // Bookmark this page
        screenState.tap(
            app.tables.cells["MainMenu.BookmarkPage"],
            forAction: Action.Bookmark
        )
        // Sign In (if unauthenticated)
        screenState.tap(
            app.cells[AccessibilityIdentifiers.MainMenu.signIn],
            to: Intro_FxASignin,
            if: "fxaUsername == nil")
        // Signed in (TODO)
        // SettingsScreen
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.settings], to: SettingsScreen)

        // "x" for close the menu and go back
        screenState.dismissOnUse = true
        screenState.backAction = cancelBackAction(for: app)
    }

    map.addScreenState(CloseTabMenu) { screenState in
        screenState.tap(
            app.scrollViews.buttons[AccessibilityIdentifiers.TabTray.deleteCloseAllButton].firstMatch,
            forAction: Action.AcceptRemovingAllTabs,
            transitionTo: HomePanelsScreen
        )
        screenState.backAction = cancelBackAction(for: app)
    }
}
