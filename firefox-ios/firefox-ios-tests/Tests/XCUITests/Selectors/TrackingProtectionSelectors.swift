// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TrackingProtectionSelectorsSet {
    var TRACKING_PROTECTION_SWITCH: Selector { get }
    var all: [Selector] { get }
}

struct TrackingProtectionSelectors: TrackingProtectionSelectorsSet {
    private enum IDs {
        static let trackingProtectionNormal = "prefkey.trackingprotection.normalbrowsing"
    }

    let TRACKING_PROTECTION_SWITCH = Selector.switchById(
        IDs.trackingProtectionNormal,
        description: "Tracking Protection switch for normal browsing",
        groups: ["settings", "privacy"]
    )

    var all: [Selector] { [TRACKING_PROTECTION_SWITCH] }
}
