// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerTrackingProtection(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(TrackingProtectionContextMenuDetails) { screenState in
        screenState.gesture(forAction: Action.TrackingProtectionperSiteToggle) { userState in
            app.tables.cells["tp.add-to-safelist"].waitAndTap()
            userState.trackingProtectionPerTabEnabled = !userState.trackingProtectionPerTabEnabled
        }

        screenState.gesture(
            forAction: Action.OpenSettingsFromTPMenu,
            transitionTo: TrackingProtectionSettings
        ) { userState in
            app.cells["settings"].waitAndTap()
        }

        screenState.gesture(forAction: Action.CloseTPContextMenu) { userState in
            if isTablet {
                // There is no Cancel option in iPad.
                app.otherElements["PopoverDismissRegion"].waitAndTap()
            } else {
                app.buttons[AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.closeButton].waitAndTap()
            }
        }

        screenState.tap(app.buttons["Close privacy and security menu"], to: BrowserTab)
    }
}
