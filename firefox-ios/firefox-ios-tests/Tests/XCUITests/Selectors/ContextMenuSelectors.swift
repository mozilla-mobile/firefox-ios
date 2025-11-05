// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol ContextMenuSelectorsSet {
    var OPEN_IN_PRIVATE_TAB: Selector { get }
    var CONTEXT_MENU_TABLE: Selector { get }
    var OPEN_IN_NEW_TAB: Selector { get }
    var OPEN_IN_NEW_PRIVATE_TAB: Selector { get }
    var COPY_LINK: Selector { get }
    var DOWNLOAD_LINK: Selector { get }
    var SHARE_LINK: Selector { get }
    var BOOKMARK_LINK: Selector { get }
    var SWITCH_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct ContextMenuSelectors: ContextMenuSelectorsSet {
    private enum IDs {
        static let openNewTabLink = "Open in New Tab"
        static let openInNewPrivateTab = "Open in a Private Tab"
        static let openNewPrivateTabLink = "Open in New Private Tab"
        static let copyLink = "Copy Link"
        static let downloadLink = "Download Link"
        static let shareLink = "Share Link"
        static let bookmarkLink = "Bookmark Link"
        static let switchButton = "Switch"
    }

    let CONTEXT_MENU_TABLE = Selector.tableIdOrLabel(
        "Context Menu",
        description: "Context Menu table",
        groups: ["contextmenu"]
    )

    let OPEN_IN_PRIVATE_TAB = Selector.buttonId(
        IDs.openInNewPrivateTab,
        description: "Context menu option: Open in a Private Tab",
        groups: ["contextmenu"]
    )

    let OPEN_IN_NEW_TAB = Selector.buttonByLabel(
        IDs.openNewTabLink,
        description: "Context menu option 'Open in New Tab'",
        groups: ["contextmenu", "links"]
    )

    let OPEN_IN_NEW_PRIVATE_TAB = Selector.buttonByLabel(
        IDs.openNewPrivateTabLink,
        description: "Context menu option 'Open in New Private Tab'",
        groups: ["contextmenu", "links"]
    )

    let COPY_LINK = Selector.buttonByLabel(
        IDs.copyLink,
        description: "Context menu option 'Copy Link'",
        groups: ["contextmenu", "links"]
    )

    let DOWNLOAD_LINK = Selector.buttonByLabel(
        IDs.downloadLink,
        description: "Context menu option 'Download Link'",
        groups: ["contextmenu", "links"]
    )

    let SHARE_LINK = Selector.buttonByLabel(
        IDs.shareLink,
        description: "Context menu option 'Share Link'",
        groups: ["contextmenu", "links"]
    )

    let BOOKMARK_LINK = Selector.buttonByLabel(
        IDs.bookmarkLink,
        description: "Context menu option 'Bookmark Link'",
        groups: ["contextmenu", "links"]
    )

    let SWITCH_BUTTON = Selector.buttonByLabel(
        IDs.switchButton,
        description: "Toast button to switch to the newly opened private tab",
        groups: ["contextmenu"]
    )

    var all: [Selector] { [OPEN_IN_PRIVATE_TAB, CONTEXT_MENU_TABLE, OPEN_IN_NEW_TAB, OPEN_IN_NEW_PRIVATE_TAB,
                           COPY_LINK, DOWNLOAD_LINK, SHARE_LINK, BOOKMARK_LINK, SWITCH_BUTTON] }
}
