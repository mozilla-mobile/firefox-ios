// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

private func configureURLBarAvailable(_ screenState: MMScreenStateNode<FxUserState>, app: XCUIApplication) {
    let textField = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
    screenState.tap(textField, to: URLBarOpen)
    screenState.gesture(to: URLBarLongPressMenu) {
        textField.press(forDuration: 1.0)
    }
}

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

// swiftlint:disable all
func registerToolBarNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(NewTabScreen) { screenState in
        screenState.noop(to: HomePanelsScreen)
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]

        if isTablet {
            screenState.tap(tabsButton, to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                tabsButton.waitAndTap()
            }
        }
        configureURLBarAvailable(screenState, app: app)
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

    map.addScreenState(BrowserTab) { screenState in
        configureURLBarAvailable(screenState, app: app)

        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton],
            to: BrowserTabMenu
        )

        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
            to: TrackingProtectionContextMenuDetails
        )

        if isTablet {
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton],
            forAction: Action.GoToHomePage)
            } else {
                screenState.tap(
                    app.buttons[AccessibilityIdentifiers.Toolbar.homeButton],
                forAction: Action.GoToHomePage)
            }

        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.searchButton],
            forAction: Action.ClickSearchButton
        ) { userState in
        }

        configureToolBarAvailable(screenState, app: app)
        // swiftlint:disable unused_closure_parameter
        let link = app.webViews.element(boundBy: 0).links.element(boundBy: 0)
        let image = app.webViews.element(boundBy: 0).images.element(boundBy: 0)
        // swiftlint:enable unused_closure_parameter

        screenState.press(link, to: WebLinkContextMenu)
        screenState.press(image, to: WebImageContextMenu)

        let reloadButton = app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton]
        // swiftlint:disable unused_closure_parameter
        screenState.press(reloadButton, to: ReloadLongPressMenu)
        screenState.tap(reloadButton, forAction: Action.ReloadURL, transitionTo: WebPageLoading) { _ in }
        // swiftlint:enable unused_closure_parameter

        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        // For iPad there is no long press on tabs button
        if !isTablet {
            screenState.press(tabsButton, to: TabTrayLongPressMenu)
        }

        if isTablet {
            screenState.tap(tabsButton, to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                tabsButton.waitAndTap()
            }
        }

        screenState.tap(
            app.buttons["TopTabsViewController.privateModeButton"],
            forAction: Action.TogglePrivateModeFromTabBarBrowserTab
        ) { userState in
            userState.isPrivate = !userState.isPrivate
        }
    }
}
// swiftlint:enable all
