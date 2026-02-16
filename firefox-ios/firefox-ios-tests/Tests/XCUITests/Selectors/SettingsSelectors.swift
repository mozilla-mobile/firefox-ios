// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SettingsSelectorsSet {
    var SETTINGS_TABLE: Selector { get }
    var DONE_BUTTON: Selector { get }
    var SETTINGS_TITLE: Selector { get }

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
    var TABLE: Selector { get }

    // Browsing
    var BROWSING_LINKS_SECTION: Selector { get }
    var BLOCK_POPUPS_SWITCH: Selector { get }
    var TOOLBAR_CELL: Selector { get }
    var DEFAULT_BROWSER_CELL: Selector { get }
    var BROWSING_CELL_TITLE: Selector { get }
    var BLOCK_IMAGES_SWITCH_TITLE: Selector { get }

    // Send Data
    var SEND_DATA_CELL: Selector { get }
    var SEND_CRASH_REPORTS_CELL: Selector { get }

    // Translation
    var TRANSLATION_CELL_TITLE: Selector { get }

    var NO_IMAGE_MODE_STATUS_SWITCH: Selector { get }

    func ALL_CELLS() -> [Selector]

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
        static let settingTitle = "Settings"
        static let toolbarCellSettings = AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting
        static let defaultBrowserSettings = AccessibilityIdentifiers.Settings.DefaultBrowser.defaultBrowser
        static let browsingCellTitle = AccessibilityIdentifiers.Settings.Browsing.title
        static let blockImages = AccessibilityIdentifiers.Settings.BlockImages.title
        static let noImageModeStatus = "NoImageModeStatus"
        static let translationCellTitle = AccessibilityIdentifiers.Settings.Translation.title
        static let sendData = "settings.sendUsageData"
        static let sendCrashReports = "settings.sendCrashReports"
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

    let SETTINGS_TITLE = Selector.staticTextId(
        IDs.settingTitle,
        description: "Settings Screen Title Label",
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

    let TABLE = Selector.tableFirstMatch(
        description: "Main Settings table",
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

    let TOOLBAR_CELL = Selector.tableCellById(
        IDs.toolbarCellSettings,
        description: "Toolbar Search Bar Setting",
        groups: ["settings"]
    )

    let DEFAULT_BROWSER_CELL = Selector.tableCellById(
        IDs.defaultBrowserSettings,
        description: "Default browser cell in Settings",
        groups: ["settings"]
    )

    let BROWSING_CELL_TITLE = Selector.tableCellById(
        IDs.browsingCellTitle,
        description: "Browsing settings cell",
        groups: ["settings", "browsing"]
    )

    let BLOCK_IMAGES_SWITCH_TITLE = Selector.anyId(
        IDs.blockImages,
        description: "Block Images switch in Browsing settings",
        groups: ["settings", "browsing"]
    )

    let NO_IMAGE_MODE_STATUS_SWITCH = Selector.anyId(
        IDs.noImageModeStatus,
        description: "No Image Mode Status switch",
        groups: ["settings"]
    )

    let TRANSLATION_CELL_TITLE = Selector.tableCellById(
        IDs.translationCellTitle,
        description: "Translation settings cell",
        groups: ["settings", "translation"]
    )

    let SEND_DATA_CELL = Selector.switchById(
        IDs.sendData,
        description: "Send Technical Data settings cell",
        groups: ["settings", "send data"]
    )

    let SEND_CRASH_REPORTS_CELL = Selector.switchById(
        IDs.sendCrashReports,
        description: "Send Crash Reports settings cell",
        groups: ["settings", "send data"]
    )

    func ALL_CELLS() -> [Selector] {
        let s = AccessibilityIdentifiers.Settings.self
        return [
            Selector.tableCellById(s.DefaultBrowser.defaultBrowser,
                                   description: "Default Browser setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.ConnectSetting.title,
                                   description: "Connect setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Search.title,
                                   description: "Search setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.NewTab.title,
                                   description: "New Tab setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Homepage.homeSettings,
                                   description: "Homepage setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Browsing.title,
                                   description: "Browsing setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Theme.title,
                                   description: "Theme setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.AppIconSelection.settingsRowTitle,
                                   description: "App Icon row",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Siri.title,
                                   description: "Siri setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.AutofillsPasswords.title,
                                   description: "Autofills/Passwords setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.ClearData.title,
                                   description: "Clear Data setting",
                                   groups: ["settings"]),
            Selector.switchByIdOrLabel(s.ClosePrivateTabs.title,
                                       description: "Close Private Tabs switch",
                                       groups: ["settings"]),
            Selector.tableCellById(s.ContentBlocker.title,
                                   description: "Content Blocker setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Notifications.title,
                                   description: "Notifications setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.PrivacyPolicy.title,
                                   description: "Privacy Policy setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.SendFeedback.title,
                                   description: "Send Feedback setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.ShowIntroduction.title,
                                   description: "Show Introduction setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.SendData.sendTechnicalDataTitle,
                                   description: "Send Technical Data setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.SendData.sendDailyUsagePingTitle,
                                   description: "Send Daily Usage Ping setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.SendData.sendCrashReportsTitle,
                                   description: "Send Crash Reports setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.SendData.studiesTitle,
                                   description: "Studies setting",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Version.title,
                                   description: "Version cell",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Help.title,
                                   description: "Help cell",
                                   groups: ["settings"]),
            Selector.tableCellById(s.RateOnAppStore.title,
                                   description: "Rate App Store cell",
                                   groups: ["settings"]),
            Selector.tableCellById(s.Licenses.title,
                                   description: "Licenses cell",
                                   groups: ["settings"]),
            Selector.tableCellById(s.YourRights.title,
                                   description: "Your Rights cell",
                                   groups: ["settings"])
        ]
    }

    var all: [Selector] {
        [SETTINGS_TABLE, DONE_BUTTON, SETTINGS_TITLE, AUTOFILLS_PASSWORDS_CELL, CLEAR_DATA_CELL,
         CLOSE_PRIVATE_TABS_SWITCH, CONTENT_BLOCKER_CELL, NOTIFICATIONS_CELL,
         PRIVACY_POLICY_CELL, LOGINS_CELL, CREDIT_CARDS_CELL, ADDRESS_CELL,
         CLEAR_PRIVATE_DATA_CELL, ALERT_OK_BUTTON, NEW_TAB_CELL, TITLE, TABLE, BROWSING_LINKS_SECTION,
         NAVIGATIONBAR, CONNECT_SETTING, BLOCK_POPUPS_SWITCH, TOOLBAR_CELL, DEFAULT_BROWSER_CELL,
         BROWSING_CELL_TITLE, BLOCK_IMAGES_SWITCH_TITLE, NO_IMAGE_MODE_STATUS_SWITCH, TRANSLATION_CELL_TITLE,
         SEND_DATA_CELL, SEND_CRASH_REPORTS_CELL]
    }
}
