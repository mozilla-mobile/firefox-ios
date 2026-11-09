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
    var DETAILS_BACK_BUTTON: Selector { get }
    var DETAILS_TITLE_LABEL: Selector { get }
    var DETAILS_CERTIFICATES_BUTTON: Selector { get }
    var CERTIFICATES_TITLE_LABEL: Selector { get }
    var CERTIFICATES_TABLE: Selector { get }
    func certificateSection(named name: String) -> Selector
    var PANEL_TITLE_LABEL: Selector { get }
    var PANEL_SUBTITLE_LABEL: Selector { get }
    var PANEL_CLOSE_BUTTON: Selector { get }
    var PANEL_TRACKING_PROTECTION_SWITCH: Selector { get }
    var PANEL_PRIVACY_SETTINGS_BUTTON: Selector { get }
    var PANEL_FOX_IMAGE: Selector { get }
    var PANEL_CONNECTION_DETAILS_TITLE: Selector { get }
    var PANEL_CONNECTION_DETAILS_STATUS: Selector { get }
    var PANEL_TRACKERS_BUTTON: Selector { get }
    var PANEL_CLEAR_COOKIES_BUTTON: Selector { get }
    var CLEAR_COOKIES_ALERT: Selector { get }
    var CLEAR_COOKIES_TOAST: Selector { get }
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
        description: "Close button on the connection details and certificate screens",
        groups: ["privacy", "trackingProtection"]
    )

    let DETAILS_BACK_BUTTON = Selector.buttonId(
        IDs.detailsScreen.backButton,
        description: "Back button on the connection details and certificate screens",
        groups: ["privacy", "trackingProtection"]
    )

    let DETAILS_TITLE_LABEL = Selector.staticTextId(
        IDs.detailsScreen.titleLabel,
        description: "Website name in the connection details and certificate screen headers",
        groups: ["privacy", "trackingProtection"]
    )

    let DETAILS_CERTIFICATES_BUTTON = Selector.buttonId(
        IDs.detailsScreen.certificatesButton,
        description: "View certificate link on the connection details screen",
        groups: ["privacy", "trackingProtection"]
    )

    let CERTIFICATES_TITLE_LABEL = Selector.staticTextId(
        IDs.detailsScreen.certificatesTitleLabel,
        description: "\"Certificate\" title on the certificate screen",
        groups: ["privacy", "trackingProtection"]
    )

    let CERTIFICATES_TABLE = Selector.tableIdOrLabel(
        IDs.detailsScreen.tableView,
        description: "Certificate details table on the certificate screen",
        groups: ["privacy", "trackingProtection"]
    )

    func certificateSection(named name: String) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND identifier == %@ AND label == %@",
            XCUIElement.ElementType.staticText.rawValue,
            IDs.detailsScreen.sectionLabel,
            name
        )
        return Selector(
            strategy: .predicate(predicate),
            value: name,
            description: "Certificate section titled '\(name)'",
            groups: ["privacy", "trackingProtection"]
        )
    }

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

    let PANEL_FOX_IMAGE = Selector.imageById(
        IDs.mainScreen.foxImage,
        description: "Fox illustration in the tracking protection panel, grayscale when protections are off",
        groups: ["privacy", "trackingProtection"]
    )

    let PANEL_CONNECTION_DETAILS_TITLE = Selector.staticTextId(
        IDs.mainScreen.connectionDetailsTitleLabel,
        description: "Title next to the fox illustration in the tracking protection panel",
        groups: ["privacy", "trackingProtection"]
    )

    let PANEL_CONNECTION_DETAILS_STATUS = Selector.staticTextId(
        IDs.mainScreen.connectionDetailsStatusLabel,
        description: "Status text next to the fox illustration in the tracking protection panel",
        groups: ["privacy", "trackingProtection"]
    )

    let PANEL_TRACKERS_BUTTON = Selector.buttonId(
        IDs.mainScreen.trackersBlockedButton,
        description: "Trackers section button in the tracking protection panel",
        groups: ["privacy", "trackingProtection"]
    )

    let PANEL_CLEAR_COOKIES_BUTTON = Selector.buttonId(
        IDs.mainScreen.clearCookiesButton,
        description: "Clear cookies and site data button in the tracking protection panel",
        groups: ["privacy", "trackingProtection"]
    )

    let CLEAR_COOKIES_ALERT = Selector.alertByTitle(
        String.Menu.EnhancedTrackingProtection.clearDataAlertTitle,
        description: "Confirmation alert opened by Clear cookies and site data",
        groups: ["privacy", "trackingProtection"]
    )

    let CLEAR_COOKIES_TOAST = Selector.staticTextByLabel(
        String.Menu.EnhancedTrackingProtection.clearDataToastMessage,
        description: "Toast shown after clearing cookies and site data from the panel",
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
         DETAILS_VERIFIED_BY_LABEL, DETAILS_CLOSE_BUTTON, DETAILS_BACK_BUTTON, DETAILS_TITLE_LABEL,
         DETAILS_CERTIFICATES_BUTTON, CERTIFICATES_TITLE_LABEL, CERTIFICATES_TABLE, PANEL_TITLE_LABEL,
         PANEL_SUBTITLE_LABEL,
         PANEL_CLOSE_BUTTON, PANEL_TRACKING_PROTECTION_SWITCH, PANEL_PRIVACY_SETTINGS_BUTTON,
         PANEL_FOX_IMAGE, PANEL_CONNECTION_DETAILS_TITLE, PANEL_CONNECTION_DETAILS_STATUS, PANEL_TRACKERS_BUTTON,
         PANEL_CLEAR_COOKIES_BUTTON, CLEAR_COOKIES_ALERT, CLEAR_COOKIES_TOAST,
         SETTINGS_NAVIGATION_BAR, SETTINGS_BACK_BUTTON, SETTINGS_DONE_BUTTON, SETTINGS_STANDARD_CELL,
         SETTINGS_STRICT_CELL]
    }
}
