// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerHomePanelNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(HomePanel_TopSites) { screenState in
        let topSites = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        screenState.press(
            topSites.cells.matching(
                identifier: AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
            ).element(boundBy: 0),
            to: TopSitesPanelContextMenu
        )
    }

    map.addScreenState(HomePanelsScreen) { screenState in
        if isTablet {
            screenState.tap(
                app.buttons[AccessibilityIdentifiers.Browser.TopTabs.privateModeButton],
                forAction: Action.TogglePrivateModeFromTabBarHomePanel
            ) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }

        // Workaround to bug Bug 1417522
        if isTablet {
            screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            }
        }

        screenState.gesture(forAction: Action.CloseURLBarOpen, transitionTo: HomePanelsScreen) {_ in
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }
    }

    map.addScreenState(HomeSettings) { screenState in
        screenState.gesture(forAction: Action.SelectHomeAsFirefoxHomePage) { UserState in
            app.cells["HomeAsFirefoxHome"].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectHomeAsCustomURL) { UserState in
            app.cells["HomeAsCustomURL"].waitAndTap()
        }

        screenState.gesture(forAction: Action.TogglePocketInNewTab) { userState in
            userState.pocketInNewTab = !userState.pocketInNewTab
            app.tables.cells.switches["Thought-Provoking Stories, Articles powered by Pocket"].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectTopSitesRows) { userState in
            app.tables.cells["TopSitesRows"].waitAndTap()
            select(rows: userState.numTopSitesRows, in: app)
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).waitAndTap()
        }

        screenState.gesture(forAction: Action.ToggleRecentlySaved) { userState in
            app.tables.cells.switches["Bookmarks"].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectShortcuts) { userState in
            let topSitesSetting = AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage
            app.tables.cells[topSitesSetting].waitAndTap()
        }

        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(HomePanel_Library) { screenState in
        let librarySegmentControl = app.segmentedControls["librarySegmentControl"]
        screenState.dismissOnUse = true
        screenState.backAction = navigationControllerBackAction(for: app)

        screenState.tap(
            librarySegmentControl.buttons.element(boundBy: 0),
            to: LibraryPanel_Bookmarks
        )
        screenState.tap(
            librarySegmentControl.buttons.element(boundBy: 1),
            to: LibraryPanel_History
        )
        screenState.tap(
            librarySegmentControl.buttons.element(boundBy: 2),
            to: LibraryPanel_Downloads
        )
        screenState.tap(
            librarySegmentControl.buttons.element(boundBy: 3),
            to: LibraryPanel_ReadingList
        )
    }
}
