// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

enum NavigationRegistry {
    static func registerAll(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
        registerZoomNavigation(in: map, app: app)
        registerToolBarNavigation(in: map, app: app)
        registerSettingsNavigation(in: map, app: app)
        registerUrlBarNavigation(in: map, app: app)
        registerLibraryPanelNavigation(in: map, app: app)
        registerHomePanelNavigation(in: map, app: app)
        registerTabMenuNavigation(in: map, app: app)
        registerTabTrayNavigation(in: map, app: app)
        registerCommonNavigation(in: map, app: app)
        registerOnboardingNavigation(in: map, app: app)
        registerMobileNavigation(in: map, app: app)
        registerTrackingProtection(in: map, app: app)
        registerContextMenuNavigation(in: map, app: app)
        registerFxAccountNavigation(in: map, app: app)
        registerMiscellanousNavigation(in: map, app: app)
        registerMiscellanousActions(in: map)
    }
}
