// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol PhotonActionSheetSelectorsSet {
    var SETTINGS_MENU_BUTTON: Selector { get }
    var PHOTON_ACTION_SHEET_NAVIGATION_BAR: Selector { get }
    var PHOTON_ACTION_SHEET_WEBSITE_TITLE: Selector { get }
    var PHOTON_ACTION_SHEET_WEBSITE_URL: Selector { get }
    var PHOTON_ACTION_SHEET_COPY_BUTTON: Selector { get }
    var PHOTON_ACTION_SHEET_SHARE_VIEW: Selector { get }
    var PHOTON_ACTION_SHEET_FENNEC_ICON: Selector { get }
    var SHARE_VIEW_OPEN_IN_FIREFOX: Selector { get }
    var SHARE_VIEW_LOAD_IN_BACKGROUND: Selector { get }
    var SHARE_VIEW_BOOKMARK_THIS_PAGE: Selector { get }
    var SHARE_VIEW_ADD_TO_READING_LIST: Selector { get }
    var SHARE_VIEW_SEND_TO_DEVICE: Selector { get }
    var ACTIVITY_LIST_VIEW: Selector { get }
    var all: [Selector] { get }
}

struct PhotonActionSheetSelectors: PhotonActionSheetSelectorsSet {
    private enum IDs {
        static let settingsMenuButton = AccessibilityIdentifiers.Toolbar.settingsMenuButton
        static let photonActionSheetNavigationBar = "UIActivityContentView"
        static let photonActionSheetWebsiteTitle = "Example Domain"
        static let photonActionSheetWebsiteURL = "example.com"
        static let photonActionSheetCopyButton = "Copy"
        static let shareView = "ShareTo.ShareView"
        static let fennecIcon = "Fennec"
        static let shareViewOpenInFirefox = "Open in Firefox"
        static let shareViewLoadInBackground = "Load in Background"
        static let shareViewBookmarkThisPage = "Bookmark This Page"
        static let shareViewAddToReadingList = "Add to Reading List"
        static let shareViewSendToDevice = "Send to Device"
        static let activityListView = "ActivityListView"
    }

    let SETTINGS_MENU_BUTTON = Selector.buttonId(
        IDs.settingsMenuButton,
        description: "Settings menu button on the toolbar",
        groups: ["toolbar"]
    )

    let PHOTON_ACTION_SHEET_NAVIGATION_BAR = Selector.navigationBarId(
        IDs.photonActionSheetNavigationBar,
        description: "Photon action sheet's navigation bar",
        groups: ["photonActionSheet"]
    )

    let PHOTON_ACTION_SHEET_WEBSITE_TITLE = Selector.anyId(
        IDs.photonActionSheetWebsiteTitle,
        description: "Photon action sheet's website title",
        groups: ["photonActionSheet"]
    )

    let PHOTON_ACTION_SHEET_WEBSITE_URL = Selector.otherElementId(
        IDs.photonActionSheetWebsiteURL,
        description: "Photon action sheet's website URL",
        groups: ["photonActionSheet"]
    )

    let PHOTON_ACTION_SHEET_COPY_BUTTON = Selector.anyId(
        IDs.photonActionSheetCopyButton,
        description: "Copy button from share view",
        groups: ["photonActionSheet"]
    )

    let PHOTON_ACTION_SHEET_SHARE_VIEW = Selector.navigationBarId(
        IDs.shareView,
        description: "Share view after tapping fennec icon",
        groups: ["photonActionSheet"]
    )

    let PHOTON_ACTION_SHEET_FENNEC_ICON = Selector.staticTextLabelContains(
        IDs.fennecIcon,
        description: "Fennec icon from photon action sheet",
        groups: ["photonActionSheet"]
    )

    let SHARE_VIEW_OPEN_IN_FIREFOX = Selector.staticTextId(
        IDs.shareViewOpenInFirefox,
        description: "Send to Firefox from share view",
        groups: ["photonActionSheet"]
    )

    let SHARE_VIEW_LOAD_IN_BACKGROUND = Selector.staticTextId(
        IDs.shareViewLoadInBackground,
        description: "Load in Background from share view",
        groups: ["photonActionSheet"]
    )

    let SHARE_VIEW_BOOKMARK_THIS_PAGE = Selector.staticTextId(
        IDs.shareViewBookmarkThisPage,
        description: "Bookmark This Page from share view",
        groups: ["photonActionSheet"]
    )

    let SHARE_VIEW_ADD_TO_READING_LIST = Selector.staticTextId(
        IDs.shareViewAddToReadingList,
        description: "Add to Reading List from share view",
        groups: ["photonActionSheet"]
    )

    let SHARE_VIEW_SEND_TO_DEVICE = Selector.staticTextId(
        IDs.shareViewSendToDevice,
        description: "Send to Device from share view",
        groups: ["photonActionSheet"]
    )

    let ACTIVITY_LIST_VIEW = Selector.otherElementId(
        IDs.activityListView,
        description: "iOS system share sheet activity list view",
        groups: ["photonActionSheet", "system"]
    )

    var all: [Selector] { [SETTINGS_MENU_BUTTON, PHOTON_ACTION_SHEET_NAVIGATION_BAR,
        PHOTON_ACTION_SHEET_WEBSITE_TITLE, PHOTON_ACTION_SHEET_WEBSITE_URL,
        PHOTON_ACTION_SHEET_COPY_BUTTON, PHOTON_ACTION_SHEET_SHARE_VIEW,
        PHOTON_ACTION_SHEET_FENNEC_ICON, SHARE_VIEW_OPEN_IN_FIREFOX,
        SHARE_VIEW_LOAD_IN_BACKGROUND, SHARE_VIEW_BOOKMARK_THIS_PAGE,
        SHARE_VIEW_ADD_TO_READING_LIST, SHARE_VIEW_SEND_TO_DEVICE, ACTIVITY_LIST_VIEW] }
}
