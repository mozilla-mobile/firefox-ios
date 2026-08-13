// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

extension BookmarkItemData {
    func copy(with title: String, url: String) -> BookmarkItemData {
        return BookmarkItemData(guid: guid,
                                dateAdded: dateAdded,
                                lastModified: lastModified,
                                parentGUID: parentGUID,
                                position: position,
                                url: url,
                                title: title)
    }
}
