// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol MainMenuSelectorSet {
    var DESKTOP_SITE: Selector { get }
    var all: [Selector] { get }
}

struct MainMenuSelectors: MainMenuSelectorSet {
    private enum IDs {
        static let desktopSite = AccessibilityIdentifiers.MainMenu.desktopSite
    }

    let DESKTOP_SITE = Selector.cellById(
        IDs.desktopSite,
        description: "Desktop Site",
        groups: ["MainMenu"]
    )

    var all: [Selector] { [DESKTOP_SITE] }
}
