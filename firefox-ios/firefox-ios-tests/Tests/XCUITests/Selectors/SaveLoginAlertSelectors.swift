// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

protocol SaveLoginAlertSelectorsSet {
    var ALERT_TITLE: Selector { get }
    var DONT_UPDATE_BUTTON: Selector { get }
    var UPDATE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct SaveLoginAlertSelectors: SaveLoginAlertSelectorsSet {
    private enum IDs {
        static let alertTitle = "Update password?"
    }

    let ALERT_TITLE = Selector.staticTextByLabel(
        IDs.alertTitle,
        description: "Alert asking to update saved password",
        groups: ["alert", "logins"]
    )

    let DONT_UPDATE_BUTTON = Selector.buttonId(
        AccessibilityIdentifiers.SaveLoginAlert.dontUpdateButton,
        description: "Don't Update button in Save Login alert",
        groups: ["alert", "logins"]
    )

    let UPDATE_BUTTON = Selector.buttonId(
        AccessibilityIdentifiers.SaveLoginAlert.updateButton,
        description: "Update button in Save Login alert",
        groups: ["alert", "logins"]
    )

    var all: [Selector] { [ALERT_TITLE, DONT_UPDATE_BUTTON, UPDATE_BUTTON] }
}
