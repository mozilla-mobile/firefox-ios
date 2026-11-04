// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SyncSelectorsSet {
    var FIREFOX_SYNC_TITLE: Selector { get }
    var SYNC_AND_SAVE_DATA_BUTTON: Selector { get }
    var SYNC_AND_SAVE_DATA_NAVIGATION_BAR: Selector { get }
    var FXA_WEBVIEW_NAVIGATION_BAR: Selector { get }
    var FXA_WEBVIEW_CLOSE_BUTTON: Selector { get }
    var SETTINGS_SYNC_AND_SAVE_DATA_ROW: Selector { get }
    var EMAIL_SIGN_IN_BUTTON: Selector { get }
    var EMAIL_PLACEHOLDER_TEXT: Selector { get }
    var FXA_WEBVIEW: Selector { get }
    var FXA_EMAIL_FIELD: Selector { get }
    var all: [Selector] { get }
}

struct SyncSelectors: SyncSelectorsSet {
    private enum IDs {
        static let firefoxSyncTitle = "Firefox Sync"
        static let syncAndSaveDataLabel = "Sync and Save Data"
        static let syncAndSaveDataNavigationBar = AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar
        static let fxaWebViewNavigationBar = "Client.FxAWebView"
        static let closeButton = String.CloseButtonTitle
        static let settingsSyncAndSaveDataRow = AccessibilityIdentifiers.Settings.FirefoxAccount.fxaSettingsButton
        static let emailSignInButton = AccessibilityIdentifiers.Settings.FirefoxAccount.fxaSignInButton
        static let emailPlaceholder = AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField
    }

    let FIREFOX_SYNC_TITLE = Selector.staticTextByLabel(
        IDs.firefoxSyncTitle,
        description: "Title shown on the signed-out Synced Tabs panel",
        groups: ["sync"]
    )

    let SYNC_AND_SAVE_DATA_BUTTON = Selector.buttonByLabel(
        IDs.syncAndSaveDataLabel,
        description: "Sign-in button shown on the signed-out Synced Tabs panel",
        groups: ["sync"]
    )

    let SYNC_AND_SAVE_DATA_NAVIGATION_BAR = Selector.navigationBarId(
        IDs.syncAndSaveDataNavigationBar,
        description: "Navigation bar of the Sync and Save Data sign-in screen",
        groups: ["sync"]
    )

    let FXA_WEBVIEW_NAVIGATION_BAR = Selector.navigationBarId(
        IDs.fxaWebViewNavigationBar,
        description: "Navigation bar of the Firefox Account web view",
        groups: ["sync"]
    )

    var FXA_WEBVIEW_CLOSE_BUTTON: Selector {
        Selector.buttonByLabel(
            IDs.closeButton,
            in: FXA_WEBVIEW_NAVIGATION_BAR,
            description: "Close button that dismisses the whole Firefox Account sheet",
            groups: ["sync"]
        )
    }

    let SETTINGS_SYNC_AND_SAVE_DATA_ROW = Selector.staticTextInTablesByLabel(
        IDs.settingsSyncAndSaveDataRow,
        description: "Sync and Save Data row in the main Settings table",
        groups: ["sync", "settings"]
    )

    let EMAIL_SIGN_IN_BUTTON = Selector.buttonId(
        IDs.emailSignInButton,
        description: "Use email instead button on the Sync and Save Data screen",
        groups: ["sync"]
    )

    let EMAIL_PLACEHOLDER_TEXT = Selector.staticTextId(
        IDs.emailPlaceholder,
        description: "Email field placeholder of the Firefox Account web view, exposed as text on iOS 16 and below",
        groups: ["sync"]
    )

    let FXA_WEBVIEW = Selector.webView(
        description: "Firefox Account web view",
        groups: ["sync"]
    )

    var FXA_EMAIL_FIELD: Selector {
        Selector.textField(
            in: FXA_WEBVIEW,
            description: "Email field of the Firefox Account web view",
            groups: ["sync"]
        )
    }

    var all: [Selector] {
        [FIREFOX_SYNC_TITLE, SYNC_AND_SAVE_DATA_BUTTON, SYNC_AND_SAVE_DATA_NAVIGATION_BAR,
         FXA_WEBVIEW_NAVIGATION_BAR, FXA_WEBVIEW_CLOSE_BUTTON, SETTINGS_SYNC_AND_SAVE_DATA_ROW,
         EMAIL_SIGN_IN_BUTTON, EMAIL_PLACEHOLDER_TEXT, FXA_WEBVIEW, FXA_EMAIL_FIELD]
    }
}
