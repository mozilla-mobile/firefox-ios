// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

// A local folder that never gets synced to Firefox Sync
// It enables us to have the desktop folders (menu, unfiled and toolbar) all under this desktop folder.
class LocalDesktopFolder: FxBookmarkNode {

    static let localDesktopFolderGuid = "localDesktopFolder________"

    var type: BookmarkNodeType {
        return .folder
    }

    var guid: String {
        return LocalDesktopFolder.localDesktopFolderGuid
    }

    var parentGUID: String? {
        return nil
    }

    var position: UInt32 {
        return 0
    }
}
