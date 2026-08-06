// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

extension BookmarkFolderData {
    func copy(withTitle title: String) -> BookmarkFolderData {
        return BookmarkFolderData(guid: guid,
                                  dateAdded: dateAdded,
                                  lastModified: lastModified,
                                  parentGUID: parentGUID,
                                  position: position,
                                  title: title,
                                  childGUIDs: childGUIDs,
                                  children: children)
    }
}
