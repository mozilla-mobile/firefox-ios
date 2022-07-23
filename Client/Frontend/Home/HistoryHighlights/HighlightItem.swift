// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

enum HighlightItemType {
    case group
    case item
}

protocol HighlightItem {
    var displayTitle: String { get }
    var description: String? { get }
    var siteUrl: URL? { get }
    var type: HighlightItemType { get }
    var group: [HighlightItem]? { get }
}

extension HistoryHighlight: HighlightItem {

    var group: [HighlightItem]? {
        nil
    }

    var type: HighlightItemType {
        .item
    }

    var displayTitle: String {
        title ?? url
    }

    var description: String? {
        nil
    }

    var siteUrl: URL? {
        URL(string: url)
    }
}
