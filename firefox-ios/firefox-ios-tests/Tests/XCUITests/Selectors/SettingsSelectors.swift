// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SettingsSelectorsSet {
    var SETTINGS_TABLE: Selector { get }
    var DONE_BUTTON: Selector { get }

    // Privacy Options
    var AUTOFILLS_PASSWORDS_CELL: Selector { get }
    var CLEAR_DATA_CELL: Selector { get }
    var CLOSE_PRIVATE_TABS_SWITCH: Selector { get }
    var CONTENT_BLOCKER_CELL: Selector { get }
    var NOTIFICATIONS_CELL: Selector { get }
    var PRIVACY_POLICY_CELL: Selector { get }

    // Autofill & Password Options
    var LOGINS_CELL: Selector { get }
    var CREDIT_CARDS_CELL: Selector { get }
    var ADDRESS_CELL: Selector { get }
    var CLEAR_PRIVATE_DATA_CELL: Selector { get }
    var ALERT_OK_BUTTON: Selector { get }

    // General
    var NEW_TAB_CELL: Selector { get }
    var TITLE: Selector { get }
    var NAVIGATIONBAR: Selector { get }
    var CONNECT_SETTING: Selector { get }

    // Browsing
    var BROWSING_LINKS_SECTION: Selector { get }
    var BLOCK_POPUPS_SWITCH: Selector { get }

    var all: [Selector] { get }
}

struct SettingsSelectors: SettingsSelectorsSet {
    private enum IDs {
        static let autofillsPasswordsTitle = AccessibilityIdentifiers.Settings.AutofillsPasswords.title
        static let clearDataTitle = AccessibilityIdentifiers.Settings.ClearData.title
        static let closePrivateTabsTitle = AccessibilityIdentifiers.Settings.ClosePrivateTabs.title
        static let contentBlockerTitle = AccessibilityIdentifiers.Settings.ContentBlocker.title
        static let notificationsTitle = AccessibilityIdentifiers.Settings.Notifications.title
        static let privacyPolicyTitle = AccessibilityIdentifiers.Settings.PrivacyPolicy.title
        static let loginsTitle = AccessibilityIdentifiers.Settings.Logins.title
        static let creditCardsTitle = AccessibilityIdentifiers.Settings.CreditCards.title
        static let addressTitle = AccessibilityIdentifiers.Settings.Address.title
        static let browsingLinks = AccessibilityIdentifiers.Settings.Browsing.links
        static let blockPopUps = AccessibilityIdentifiers.Settings.Browsing.blockPopUps
        static let title = AccessibilityIdentifiers.Settings.title
        static let navigationBarItem = AccessibilityIdentifiers.Settings.navigationBarItem
        static let connectSetting = AccessibilityIdentifiers.Settings.ConnectSetting.title
    }

    // Core Element Selector
    let SETTINGS_TABLE = Selector.firstTable(
        description: "Main settings table view (first table in hierarchy)",
        groups: ["settings"]
    )

    let DONE_BUTTON = Selector.buttonId(
        "Done",
        description: "Done button to close settings",
        groups: ["settings"]
    )

    // Privacy Options (general settings)
    let AUTOFILLS_PASSWORDS_CELL = Selector.staticTextId(
        IDs.autofillsPasswordsTitle,
        description: "Autofill and Passwords settings cell",
        groups: ["settings", "privacy"]
    )

    let CLEAR_DATA_CELL = Selector.staticTextId(
        IDs.clearDataTitle,
        description: "Clear Data settings cell",
        groups: ["settings", "privacy"]
    )

    let CLOSE_PRIVATE_TABS_SWITCH = Selector.staticTextId(
        IDs.closePrivateTabsTitle,
        description: "Close Private Tabs switch label",
        groups: ["settings", "privacy"]
    )

    let CONTENT_BLOCKER_CELL = Selector.staticTextId(
        IDs.contentBlockerTitle,
        description: "Content Blocker settings cell",
        groups: ["settings", "privacy"]
    )

    let NOTIFICATIONS_CELL = Selector.staticTextId(
        IDs.notificationsTitle,
        description: "Notifications settings cell",
        groups: ["settings", "privacy"]
    )

    let PRIVACY_POLICY_CELL = Selector.staticTextId(
        IDs.privacyPolicyTitle,
        description: "Privacy Policy settings cell",
        groups: ["settings", "privacy"]
    )

    // Autofill & Password Options (sub-menu)
    let LOGINS_CELL = Selector.staticTextId(
        IDs.loginsTitle,
        description: "Logins settings cell",
        groups: ["settings", "autofill"]
    )

    let CREDIT_CARDS_CELL = Selector.staticTextId(
        IDs.creditCardsTitle,
        description: "Credit Cards settings cell",
        groups: ["settings", "autofill"]
    )

    let ADDRESS_CELL = Selector.staticTextId(
        IDs.addressTitle,
        description: "Addresses settings cell",
        groups: ["settings", "autofill"]
    )

    let CLEAR_PRIVATE_DATA_CELL = Selector.tableCellById(
        "ClearPrivateData",
        description: "Cell to initiate clearing private data",
        groups: ["settings", "privacy"]
    )

    let ALERT_OK_BUTTON = Selector.buttonId(
        "OK",
        description: "OK button on confirmation alert",
        groups: ["alert"]
    )

    let NEW_TAB_CELL = Selector.tableCellById(
        "NewTab",
        description: "Cell for New Tab option in Settings",
        groups: ["settings"]
    )

    let TITLE = Selector.buttonId(
        IDs.title,
        description: "Settings Title",
        groups: ["settings"]
    )

    let NAVIGATIONBAR = Selector.buttonId(
        IDs.navigationBarItem,
        description: "Navigation Bar Item",
        groups: ["settings"]
    )

    let CONNECT_SETTING = Selector.cellById(
        IDs.connectSetting,
        description: "Connect Settings",
        groups: ["settings"]
    )

    let BROWSING_LINKS_SECTION = Selector.tableOtherById(
        IDs.browsingLinks,
        description: "Browsing Links section in Settings table",
        groups: ["settings", "browsing"]
    )

    let BLOCK_POPUPS_SWITCH = Selector.switchById(
        IDs.blockPopUps,
        description: "Switch for 'Block Pop-Ups' in Settings → Browsing",
        groups: ["settings", "browsing"]
    )

    var all: [Selector] {
        [SETTINGS_TABLE, DONE_BUTTON, AUTOFILLS_PASSWORDS_CELL, CLEAR_DATA_CELL,
         CLOSE_PRIVATE_TABS_SWITCH, CONTENT_BLOCKER_CELL, NOTIFICATIONS_CELL,
         PRIVACY_POLICY_CELL, LOGINS_CELL, CREDIT_CARDS_CELL, ADDRESS_CELL,
         CLEAR_PRIVATE_DATA_CELL, ALERT_OK_BUTTON, NEW_TAB_CELL, TITLE, BROWSING_LINKS_SECTION,
         NAVIGATIONBAR, CONNECT_SETTING, BLOCK_POPUPS_SWITCH]
    }
}
