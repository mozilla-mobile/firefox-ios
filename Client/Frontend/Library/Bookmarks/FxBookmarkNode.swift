// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

// Provides a layer of abstraction so we have more power over BookmarkNodeData provided by App Services.
// For instance, this enables us to have the LocalDesktopFolder.
protocol FxBookmarkNode {
    var type: BookmarkNodeType { get }
    var guid: String { get }
    var parentGUID: String? { get }
    var position: UInt32 { get }
}

extension BookmarkNodeData: FxBookmarkNode {}
