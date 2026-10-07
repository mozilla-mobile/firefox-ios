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
    var SHARE_SHEET_CLOSE_BUTTON: Selector { get }
    var SHARE_SHEET_DONE_BUTTON: Selector { get }
    var SHARE_SHEET_DISMISS_REGION: Selector { get }
    var SHARE_SHEET_HEADER: Selector { get }
    var SHARE_SHEET_TOP_CAPTION: Selector { get }
    var SHARE_SHEET_BOTTOM_CAPTION: Selector { get }
    var all: [Selector] { get }
}

struct PhotonActionSheetSelectors: PhotonActionSheetSelectorsSet {
    private enum IDs {
        static let settingsMenuButton = AccessibilityIdentifiers.Toolbar.settingsMenuButton
        static let photonActionSheetNavigationBar = "UIActivityContentView"
        static let photonActionSheetWebsiteTitle = TestLabels.exampleDomain
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
        static let shareSheetCloseButton = "header.closeButton"
        static let shareSheetCloseButtonLabel = "Close"
        static let shareSheetDoneButton = "Done"
        static let shareSheetDismissRegion = "PopoverDismissRegion"
        static let shareSheetHeader = "UIActivityContentView"
        // The share sheet header captions: the shared item's name, and its kind and size below it.
        static let shareSheetTopCaption = "LP.CaptionBar.TopCaption"
        static let shareSheetBottomCaption = "LP.CaptionBar.BottomCaption"
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

    // Older iOS leaves the button untagged, so it is only matched by its label there.
    let SHARE_SHEET_CLOSE_BUTTON = Selector(
        strategy: .predicate(NSPredicate(
            format: "elementType == %d AND (identifier == %@ OR (identifier == '' AND label == %@))",
            XCUIElement.ElementType.button.rawValue,
            IDs.shareSheetCloseButton,
            IDs.shareSheetCloseButtonLabel
        )),
        value: IDs.shareSheetCloseButton,
        description: "Close button in the system share sheet's header",
        groups: ["photonActionSheet", "system"]
    )

    let SHARE_SHEET_DONE_BUTTON = Selector.buttonIdOrLabel(
        IDs.shareSheetDoneButton,
        description: "Done button dismissing the system share sheet",
        groups: ["photonActionSheet", "system"]
    )

    let SHARE_SHEET_DISMISS_REGION = Selector.otherElementId(
        IDs.shareSheetDismissRegion,
        description: "Region outside the share sheet popover that dismisses it when tapped",
        groups: ["photonActionSheet", "system"]
    )

    let SHARE_SHEET_HEADER = Selector.navigationBarId(
        IDs.shareSheetHeader,
        description: "Share sheet header holding the shared item's thumbnail, captions and Close button",
        groups: ["photonActionSheet", "system"]
    )

    let SHARE_SHEET_TOP_CAPTION = Selector.otherElementId(
        IDs.shareSheetTopCaption,
        description: "Share sheet header caption naming the shared item",
        groups: ["photonActionSheet", "system"]
    )

    let SHARE_SHEET_BOTTOM_CAPTION = Selector.otherElementId(
        IDs.shareSheetBottomCaption,
        description: "Share sheet header caption describing the shared item's kind and size",
        groups: ["photonActionSheet", "system"]
    )

    var all: [Selector] { [SETTINGS_MENU_BUTTON, PHOTON_ACTION_SHEET_NAVIGATION_BAR,
                           PHOTON_ACTION_SHEET_WEBSITE_TITLE, PHOTON_ACTION_SHEET_WEBSITE_URL,
                           PHOTON_ACTION_SHEET_COPY_BUTTON, PHOTON_ACTION_SHEET_SHARE_VIEW,
                           PHOTON_ACTION_SHEET_FENNEC_ICON, SHARE_VIEW_OPEN_IN_FIREFOX,
                           SHARE_VIEW_LOAD_IN_BACKGROUND, SHARE_VIEW_BOOKMARK_THIS_PAGE,
                           SHARE_VIEW_ADD_TO_READING_LIST, SHARE_VIEW_SEND_TO_DEVICE, ACTIVITY_LIST_VIEW,
                           SHARE_SHEET_CLOSE_BUTTON, SHARE_SHEET_DONE_BUTTON,
                           SHARE_SHEET_HEADER, SHARE_SHEET_TOP_CAPTION, SHARE_SHEET_BOTTOM_CAPTION,
                           SHARE_SHEET_DISMISS_REGION] }
}
