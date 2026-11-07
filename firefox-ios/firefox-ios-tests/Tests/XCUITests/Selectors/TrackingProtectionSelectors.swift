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
    var PANEL_TITLE_LABEL: Selector { get }
    var PANEL_SUBTITLE_LABEL: Selector { get }
    var PANEL_CLOSE_BUTTON: Selector { get }
    var PANEL_TRACKING_PROTECTION_SWITCH: Selector { get }
    var PANEL_PRIVACY_SETTINGS_BUTTON: Selector { get }
    var SETTINGS_NAVIGATION_BAR: Selector { get }
    var SETTINGS_BACK_BUTTON: Selector { get }
    var SETTINGS_DONE_BUTTON: Selector { get }
    var SETTINGS_STANDARD_CELL: Selector { get }
    var SETTINGS_STRICT_CELL: Selector { get }
    var all: [Selector] { get }
}

struct TrackingProtectionSelectors: TrackingProtectionSelectorsSet {
    private enum IDs {
        static let trackingProtectionNormal = "prefkey.trackingprotection.normalbrowsing"
        static let mainScreen = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.self
        static let detailsScreen = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.self
        static let settingsScreen = AccessibilityIdentifiers.Settings.TrackingProtection.self
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

    let PANEL_TITLE_LABEL = Selector.staticTextId(
        IDs.mainScreen.titleLabel,
        description: "Website title in the tracking protection panel header",
        groups: ["privacy", "trackingProtection"]
    )

    let PANEL_SUBTITLE_LABEL = Selector.staticTextId(
        IDs.mainScreen.subtitleLabel,
        description: "Website domain in the tracking protection panel header",
        groups: ["privacy", "trackingProtection"]
    )

    let PANEL_CLOSE_BUTTON = Selector.buttonId(
        IDs.mainScreen.closeButton,
        description: "Close button in the tracking protection panel header",
        groups: ["privacy", "trackingProtection"]
    )

    let PANEL_TRACKING_PROTECTION_SWITCH = Selector.switchById(
        IDs.mainScreen.toggleSwitch,
        description: "Enhanced Tracking Protection switch in the tracking protection panel",
        groups: ["privacy", "trackingProtection"]
    )

    let PANEL_PRIVACY_SETTINGS_BUTTON = Selector.buttonId(
        IDs.mainScreen.trackingProtectionSettingsButton,
        description: "Privacy settings button that opens the Tracking Protection settings",
        groups: ["privacy", "trackingProtection"]
    )

    let SETTINGS_NAVIGATION_BAR = Selector.navigationBarByIdOrLabel(
        String.SettingsTrackingProtectionSectionName,
        description: "Tracking Protection settings navigation bar",
        groups: ["settings", "privacy"]
    )

    let SETTINGS_BACK_BUTTON = Selector.buttonByLabel(
        String.AppSettingsTitle,
        description: "Back button to the Settings root from Tracking Protection settings",
        groups: ["settings", "privacy"]
    )

    let SETTINGS_DONE_BUTTON = Selector.buttonByLabel(
        String.AppSettingsDone,
        description: "Done button that closes Tracking Protection settings",
        groups: ["settings", "privacy"]
    )

    let SETTINGS_STANDARD_CELL = Selector.cellById(
        IDs.settingsScreen.basic,
        description: "Standard protection level option",
        groups: ["settings", "privacy"]
    )

    let SETTINGS_STRICT_CELL = Selector.cellById(
        IDs.settingsScreen.strict,
        description: "Strict protection level option",
        groups: ["settings", "privacy"]
    )

    var all: [Selector] {
        [TRACKING_PROTECTION_SWITCH, SECURITY_STATUS_BUTTON, DETAILS_CONNECTION_STATUS_LABEL,
         DETAILS_VERIFIED_BY_LABEL, DETAILS_CLOSE_BUTTON, PANEL_TITLE_LABEL, PANEL_SUBTITLE_LABEL,
         PANEL_CLOSE_BUTTON, PANEL_TRACKING_PROTECTION_SWITCH, PANEL_PRIVACY_SETTINGS_BUTTON,
         SETTINGS_NAVIGATION_BAR, SETTINGS_BACK_BUTTON, SETTINGS_DONE_BUTTON, SETTINGS_STANDARD_CELL,
         SETTINGS_STRICT_CELL]
    }
}
