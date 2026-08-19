// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TrackingProtectionSelectorsSet {
    var TRACKING_PROTECTION_SWITCH: Selector { get }
    var SECURITY_STATUS_BUTTON: Selector { get }
    var DETAILS_CONNECTION_STATUS_LABEL: Selector { get }
    var DETAILS_VERIFIED_BY_LABEL: Selector { get }
    var DETAILS_CLOSE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct TrackingProtectionSelectors: TrackingProtectionSelectorsSet {
    private enum IDs {
        static let trackingProtectionNormal = "prefkey.trackingprotection.normalbrowsing"
        static let mainScreen = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.self
        static let detailsScreen = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.self
    }

    let TRACKING_PROTECTION_SWITCH = Selector.switchById(
        IDs.trackingProtectionNormal,
        description: "Tracking Protection switch for normal browsing",
        groups: ["settings", "privacy"]
    )

    let SECURITY_STATUS_BUTTON = Selector.buttonId(
        IDs.mainScreen.securityStatusButton,
        description: "Connection security row that opens the connection details screen",
        groups: ["privacy", "trackingProtection"]
    )

    let DETAILS_CONNECTION_STATUS_LABEL = Selector.staticTextId(
        IDs.detailsScreen.connectionStatusLabel,
        description: "Connection status label on the connection details screen",
        groups: ["privacy", "trackingProtection"]
    )

    let DETAILS_VERIFIED_BY_LABEL = Selector.staticTextId(
        IDs.detailsScreen.verifiedByLabel,
        description: "Certificate verifier label on the connection details screen",
        groups: ["privacy", "trackingProtection"]
    )

    let DETAILS_CLOSE_BUTTON = Selector.buttonId(
        IDs.detailsScreen.closeButton,
        description: "Close button on the connection details screen",
        groups: ["privacy", "trackingProtection"]
    )

    var all: [Selector] {
        [TRACKING_PROTECTION_SWITCH, SECURITY_STATUS_BUTTON, DETAILS_CONNECTION_STATUS_LABEL,
         DETAILS_VERIFIED_BY_LABEL, DETAILS_CLOSE_BUTTON]
    }
}
