// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

struct SearchHighlightItem {
    private let highlightItem: HighlightItem

    init(highlightItem: HighlightItem) {
        self.highlightItem = highlightItem
    }
    var displayTitle: String {
        highlightItem.displayTitle
    }
    var urlString: String {
        return highlightItem.urlString ?? ""
    }
    var siteURL: String {
        return urlString
    }
}
