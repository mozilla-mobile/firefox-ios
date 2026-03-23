// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SpringboardSelectorsSet {
    var FENNEC_ICONS: Selector { get }
    var NEW_TAB_BUTTON: Selector { get }
    var NEW_PRIVATE_TAB_BUTTON: Selector { get }
    var OPEN_LAST_BOOKMARK_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct SpringboardSelectors: SpringboardSelectorsSet {
    private enum IDs {
        static let fennecIconsPrefix = "Fennec "
        static let newTabButton = "New Tab"
        static let newPrivateTabButton = "New Private Tab"
        static let openLastBookmarkButton = "org.mozilla.ios.Fennec.OpenLastBookmark"
    }

    let FENNEC_ICONS = Selector(
        strategy: .predicate(
            NSPredicate(format: "identifier BEGINSWITH %@", IDs.fennecIconsPrefix)
        ),
        value: IDs.fennecIconsPrefix,
        description: "Fennec app icons on springboard",
        groups: ["springboard", "icons"]
    )

    let NEW_TAB_BUTTON = Selector.buttonId(
        IDs.newTabButton,
        description: "New Tab button in springboard context menu",
        groups: ["springboard", "context-menu"]
    )

    let NEW_PRIVATE_TAB_BUTTON = Selector.buttonId(
        IDs.newPrivateTabButton,
        description: "New Private Tab button in springboard context menu",
        groups: ["springboard", "context-menu"]
    )

    let OPEN_LAST_BOOKMARK_BUTTON = Selector.buttonId(
        IDs.openLastBookmarkButton,
        description: "Open Last Bookmark button in springboard context menu",
        groups: ["springboard", "context-menu"]
    )

    var all: [Selector] {
        [
            FENNEC_ICONS,
            NEW_TAB_BUTTON,
            NEW_PRIVATE_TAB_BUTTON,
            OPEN_LAST_BOOKMARK_BUTTON
        ]
    }
}
