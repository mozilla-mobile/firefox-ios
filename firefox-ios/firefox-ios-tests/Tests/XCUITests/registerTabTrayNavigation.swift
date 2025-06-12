// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi
import Common

func registerTabTrayNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    // This menu is only available for iPhone, NOT for iPad, no menu when long tapping on tabs button
    if !isTablet {
        map.addScreenState(TabTrayLongPressMenu) { screenState in
            screenState.dismissOnUse = true

            let plusButton = app.buttons[StandardImageIdentifiers.Large.plus]
            let closeButton = app.buttons[StandardImageIdentifiers.Large.cross]
            let privateTabButton = app.tables.cells.buttons[StandardImageIdentifiers.Large.tab]

            screenState.tap(
                plusButton,
                forAction: Action.OpenNewTabLongPressTabsButton,
                transitionTo: NewTabScreen
            )
            screenState.tap(
                closeButton,
                forAction: Action.CloseTabFromTabTrayLongPressMenu,
                Action.CloseTab,
                transitionTo: HomePanelsScreen
            )
            screenState.tap(
                privateTabButton,
                forAction: Action.OpenPrivateTabLongPressTabsButton,
                transitionTo: NewTabScreen
            ) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }
    }

    // swiftlint:disable closure_body_length
    map.addScreenState(TabTray) { screenState in
        // Both iPad and iPhone use the same accessibility identifiers for buttons,
        // even thought they may be in separate locations design wise.
        screenState.tap(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton],
                        forAction: Action.OpenNewTabFromTabTray,
                        transitionTo: NewTabScreen)
        if isTablet {
            screenState.tap(app.navigationBars.buttons["closeAllTabsButtonTabTray"], to: CloseTabMenu)
        } else {
            screenState.tap(app.toolbars.buttons["closeAllTabsButtonTabTray"], to: CloseTabMenu)
        }

        var regularModeSelector: XCUIElement
        var privateModeSelector: XCUIElement
        var syncModeSelector: XCUIElement

        var regularModeExperimentSelector: XCUIElement
        var privateModeExperimentSelector: XCUIElement
        var syncModeExperimentSelector: XCUIElement

        if isTablet {
            regularModeSelector = app.navigationBars.segmentedControls.buttons.element(boundBy: 0)
            privateModeSelector = app.navigationBars.segmentedControls.buttons.element(boundBy: 1)
            syncModeSelector = app.navigationBars.segmentedControls.buttons.element(boundBy: 2)
            regularModeExperimentSelector = regularModeSelector
            privateModeExperimentSelector = privateModeSelector
            syncModeExperimentSelector = syncModeSelector
        } else {
            regularModeSelector = app.toolbars["Toolbar"]
                .segmentedControls[AccessibilityIdentifiers.TabTray.navBarSegmentedControl].buttons.element(boundBy: 0)
            privateModeSelector = app.toolbars["Toolbar"]
                .segmentedControls[AccessibilityIdentifiers.TabTray.navBarSegmentedControl].buttons.element(boundBy: 1)
            syncModeSelector = app.toolbars["Toolbar"]
                .segmentedControls[AccessibilityIdentifiers.TabTray.navBarSegmentedControl].buttons.element(boundBy: 2)

            regularModeExperimentSelector = app.buttons["\(AccessibilityIdentifiers.TabTray.selectorCell)\(1)"]
            privateModeExperimentSelector = app.buttons["\(AccessibilityIdentifiers.TabTray.selectorCell)\(0)"]
            syncModeExperimentSelector = app.buttons["\(AccessibilityIdentifiers.TabTray.selectorCell)\(2)"]
        }
        screenState.tap(regularModeSelector, forAction: Action.ToggleRegularMode) { userState in
            userState.isPrivate = !userState.isPrivate
        }
        screenState.tap(privateModeSelector, forAction: Action.TogglePrivateMode) { userState in
            userState.isPrivate = !userState.isPrivate
        }
        screenState.tap(syncModeSelector, forAction: Action.ToggleSyncMode) { userState in
        }

        // Tab tray selector for the tab tray UI experiment
        screenState.tap(regularModeExperimentSelector, forAction: Action.ToggleExperimentRegularMode) { userState in
            userState.isPrivate = !userState.isPrivate
        }
        screenState.tap(privateModeExperimentSelector, forAction: Action.ToggleExperimentPrivateMode) { userState in
            userState.isPrivate = !userState.isPrivate
        }
        screenState.tap(syncModeExperimentSelector, forAction: Action.ToggleExperimentSyncMode) { userState in
        }

        screenState.onEnter { userState in
            let tabsTray = AccessibilityIdentifiers.TabTray.tabsTray
            let exists = NSPredicate(format: "exists == true")
            let expectation = XCTNSPredicateExpectation(predicate: exists, object: app.otherElements[tabsTray])
            let _ = XCTWaiter().wait(for: [expectation], timeout: 5) // swiftlint:disable:this redundant_discardable_let
            userState.numTabs = Int(app.otherElements[tabsTray].cells.count)
        }
    }
    // swiftlint:enable closure_body_length
}
