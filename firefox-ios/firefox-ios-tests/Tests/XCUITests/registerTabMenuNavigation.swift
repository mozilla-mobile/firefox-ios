// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerTabMenuNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(BrowserTabMenu) { screenState in
        sleep(1)

        // Tracking Protections (TODO)
        // Bookmark Page (TODO)
        // Find In Page
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.findInPage],
            to: FindInPage)
        // Desktop Site (TODO)
        // Page Zoom (TODO)
        // Web Site Dark Mode (TODO)
        // Add To Shortcuts (TODO)
        // Save As PDF (TODO)
        // Print (TODO)
        // Sign In (if unauthenticated)
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.MainMenu.signIn],
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
            app.scrollViews.buttons[AccessibilityIdentifiers.TabTray.deleteCloseAllButton],
            forAction: Action.AcceptRemovingAllTabs,
            transitionTo: HomePanelsScreen
        )
        screenState.backAction = cancelBackAction(for: app)
    }
}
