// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SyncSelectorsSet {
    var FIREFOX_SYNC_TITLE: Selector { get }
    var SYNC_AND_SAVE_DATA_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct SyncSelectors: SyncSelectorsSet {
    private enum IDs {
        static let firefoxSyncTitle = "Firefox Sync"
        static let syncAndSaveDataLabel = "Sync and Save Data"
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

    var all: [Selector] { [FIREFOX_SYNC_TITLE, SYNC_AND_SAVE_DATA_BUTTON] }
}
