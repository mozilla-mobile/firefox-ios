// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerMiscellanousNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(Shortcuts) { screenState in
        let homePage = AccessibilityIdentifiers.Settings.Homepage.homePageNavigationBar
        screenState.tap(app.navigationBars.buttons[homePage], to: HomeSettings)
    }

    map.addScreenState(FindInPage) { screenState in
        screenState.tap(app.buttons[AccessibilityIdentifiers.FindInPage.findInPageCloseButton], to: BrowserTab)
    }

    map.addScreenState(PageZoom) { screenState in
        screenState.tap(app.buttons[AccessibilityIdentifiers.ZoomPageBar.doneButton], to: BrowserTab)
    }

    map.addScreenState(ReloadLongPressMenu) { screenState in
        screenState.backAction = cancelBackAction(for: app)
        screenState.dismissOnUse = true

        let rdsButton = app.tables["Context Menu"].cells.element(boundBy: 0)
        screenState.tap(rdsButton, forAction: Action.ToggleRequestDesktopSite) { userState in
            userState.requestDesktopSite = !userState.requestDesktopSite
        }

        let trackingProtectionButton = app.tables["Context Menu"].cells.element(boundBy: 1)

        screenState.tap(
            trackingProtectionButton,
            forAction: Action.ToggleTrackingProtectionPerTabEnabled
        ) { userState in
            userState.trackingProtectionPerTabEnabled = !userState.trackingProtectionPerTabEnabled
        }
    }

    map.addScreenState(EnterNewBookmarkTitleAndUrl) { screenState in
        screenState.gesture(forAction: Action.SaveCreatedBookmark) { userState in
            app.buttons["Save"].waitAndTap()
        }
    }

    map.addScreenState(HistoryRecentlyClosed) { screenState in
        screenState.dismissOnUse = true
        screenState.tap(app.buttons["libraryPanelTopLeftButton"].firstMatch, to: LibraryPanel_History)
    }

    /*map.addScreenState("AutofillAddress") { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }*/

    map.addScreenState(AddressesSettings ) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(RequestDesktopSite) { _ in }

    map.addScreenState(RequestMobileSite) { _ in }
}
