// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

protocol HighlightItem {
    var displayTitle: String { get }
    var url2: URL? { get }
}

extension ASGroup: HighlightItem {
    var displayTitle: String {
        return searchTerm
    }

    var url2: URL? {
        return nil
    }
}

extension HistoryHighlight: HighlightItem {
    var displayTitle: String {
        return title ?? url
    }

    var url2: URL? {
        return URL(string: url)
    }
}
