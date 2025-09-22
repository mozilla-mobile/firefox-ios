// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol BrowserSelectorsSet {
    var ADDRESS_BAR: Selector { get }
    var all: [Selector] { get }
}

struct BrowserSelectors: BrowserSelectorsSet {
    private enum IDs {
        static let addressBar = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField
    }

    let ADDRESS_BAR = Selector(
        strategy: .textFieldById(IDs.addressBar),
        value: IDs.addressBar,
        description: "Browser address bar",
        groups: ["browser"]
    )

    var all: [Selector] { [ADDRESS_BAR] }
}
