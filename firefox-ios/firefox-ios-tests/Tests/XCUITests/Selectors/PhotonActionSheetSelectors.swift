// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol PhotonActionSheetSelectorsSet {
    var SETTINGS_MENU_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct PhotonActionSheetSelectors: PhotonActionSheetSelectorsSet {
    private enum IDs {
        static let settingsMenuButton = AccessibilityIdentifiers.Toolbar.settingsMenuButton
    }

    let SETTINGS_MENU_BUTTON = Selector.buttonId(
        IDs.settingsMenuButton,
        description: "Settings menu button on the toolbar",
        groups: ["toolbar"]
    )

    var all: [Selector] { [SETTINGS_MENU_BUTTON] }
}
