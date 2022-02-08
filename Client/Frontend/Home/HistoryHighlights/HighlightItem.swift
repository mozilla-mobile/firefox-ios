// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

protocol HighlightItem {
    var showTitle: String { get }
}

extension ASGroup: HighlightItem {
    var showTitle: String {
        return searchTerm
    }
}
extension HistoryHighlight: HighlightItem {
    var showTitle: String {
        return title ?? url
    }
}
