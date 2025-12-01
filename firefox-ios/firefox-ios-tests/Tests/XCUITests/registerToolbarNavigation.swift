// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

@MainActor
private func configureURLBarAvailable(_ screenState: MMScreenStateNode<FxUserState>, app: XCUIApplication) {
    let textField = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
    screenState.tap(textField, to: URLBarOpen)
    screenState.gesture(to: URLBarLongPressMenu) {
        textField.press(forDuration: 1.0)
    }
}

@MainActor
private func configureToolBarAvailable(_ screenState: MMScreenStateNode<FxUserState>, app: XCUIApplication) {
    let settingButton = app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
    let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]

    screenState.tap(settingButton, to: BrowserTabMenu)

    if isTablet {
        screenState.tap(tabsButton, to: TabTray)
    } else {
        screenState.gesture(to: TabTray) {
            tabsButton.waitAndTap()
        }
    }
}

@MainActor
func makeToolBarAvailable(_ screenState: MMScreenStateNode<FxUserState>, app: XCUIApplication) {
    screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], to: BrowserTabMenu)
    if isTablet {
        screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], to: TabTray)
    } else {
        screenState.gesture(to: TabTray) {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        }
    }
}

@MainActor
func makeURLBarAvailable(_ screenState: MMScreenStateNode<FxUserState>, app: XCUIApplication) {
    let addressToolbar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
    screenState.tap(addressToolbar, to: URLBarOpen)
    screenState.gesture(to: URLBarLongPressMenu) {
        addressToolbar.press(forDuration: 1.0)
    }
}

@MainActor
func registerToolBarNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(NewTabScreen) { screenState in
        let tabsButtonSelector = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        screenState.noop(to: HomePanelsScreen)
        if isTablet {
            screenState.tap(tabsButtonSelector, to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                tabsButtonSelector.waitAndTap()
            }
        }
        makeURLBarAvailable(screenState, app: app)
        screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], to: BrowserTabMenu)

        if isTablet {
            screenState.tap(
                app.buttons[AccessibilityIdentifiers.Browser.TopTabs.privateModeButton],
                forAction: Action.TogglePrivateModeFromTabBarNewTab
            ) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }
    }

    // swiftlint:disable closure_body_length
    map.addScreenState(BrowserTab) { screenState in
        makeURLBarAvailable(screenState, app: app)
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton],
            to: BrowserTabMenu
        )

        screenState.tap(
            app.buttons[AccessibilityIdentifiers.MainMenu.trackigProtection],
            to: TrackingProtectionContextMenuDetails
        )

        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton],
            forAction: Action.GoToHomePage)

        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.searchButton],
            forAction: Action.ClickSearchButton
        ) { userState in
        }

        makeToolBarAvailable(screenState, app: app)
        let link = app.webViews.element(boundBy: 0).links.element(boundBy: 0)
        let image = app.webViews.element(boundBy: 0).images.element(boundBy: 0)

        screenState.press(link, to: WebLinkContextMenu)
        screenState.press(image, to: WebImageContextMenu)

        let reloadButton = app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton]
        screenState.press(reloadButton, to: ReloadLongPressMenu)
        screenState.tap(reloadButton, forAction: Action.ReloadURL, transitionTo: WebPageLoading) { _ in }
        // For iPad there is no long press on tabs button
        if !isTablet {
            let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
            screenState.press(tabsButton, to: TabTrayLongPressMenu)
        }

        if isTablet {
            screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            }
        }

        screenState.tap(
            app.buttons["TopTabsViewController.privateModeButton"],
            forAction: Action.TogglePrivateModeFromTabBarBrowserTab
        ) { userState in
                userState.isPrivate = !userState.isPrivate
        }
    }
    // swiftlint:enable closure_body_length
}
