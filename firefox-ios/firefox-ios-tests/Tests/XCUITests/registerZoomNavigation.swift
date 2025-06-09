// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
import MappaMundi

func registerZoomNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(PageZoom) { screenState in
        screenState.tap(app.buttons[AccessibilityIdentifiers.ZoomPageBar.doneButton], to: BrowserTab)
    }
}
