// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

/// A folder class that enables us to have local folder presented to the user
/// We can use this folder class for:
/// - Have the menu, unfiled and toolbar folders all under a desktop folder that doesn't exists in the backend
/// - Present the menu, unfiled and toolbar folders to the users without making a backend call. Desktop folder content is fetched when folder is selected.
class LocalDesktopFolder: FxBookmarkNode {

    // Guid used locally, but never synced to Firefox Sync accounts
    static let localDesktopFolderGuid = "localDesktopFolder"

    private let forcedGuid: Guid

    init(forcedGuid: Guid = LocalDesktopFolder.localDesktopFolderGuid) {
        self.forcedGuid = forcedGuid
    }

    var type: BookmarkNodeType {
        return .folder
    }

    var guid: String {
        return forcedGuid
    }

    var parentGUID: String? {
        return nil
    }

    var position: UInt32 {
        return 0
    }
}
