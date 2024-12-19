// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

@testable import Client

struct MockFxBookmarkNode: FxBookmarkNode {
    var type: MozillaAppServices.BookmarkNodeType
    var guid: String
    var parentGUID: String?
    var position: UInt32
    var isRoot: Bool
    var title: String
}
