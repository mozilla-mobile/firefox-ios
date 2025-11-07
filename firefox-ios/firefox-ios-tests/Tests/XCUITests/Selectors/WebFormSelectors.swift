// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol WebFormSelectorsSet {
    var USERNAME_LABEL: Selector { get }
    var USERNAME_FIELD: Selector { get }
    var PASSWORD_FIELD: Selector { get }
    var all: [Selector] { get }
}

struct WebFormSelectors: WebFormSelectorsSet {
    private enum IDs {
        static let usernameLabel = "Username:"
        static let usernameField = "username"
        static let passwordField = "password"
    }

    let USERNAME_LABEL = Selector.staticTextByLabel(
        IDs.usernameLabel,
        description: "Username label in the web form",
        groups: ["browser", "webform"]
    )

    let USERNAME_FIELD = Selector.textFieldId(
        IDs.usernameField,
        description: "Username input field in web form",
        groups: ["browser", "webform"]
    )

    let PASSWORD_FIELD = Selector.textFieldId(
        IDs.passwordField,
        description: "Password input field in web form",
        groups: ["browser", "webform"]
    )

    var all: [Selector] { [USERNAME_LABEL, USERNAME_FIELD, PASSWORD_FIELD] }
}
