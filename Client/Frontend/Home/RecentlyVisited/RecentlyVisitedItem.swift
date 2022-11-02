// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

enum RecentlyVisitedItemType {
    case group
    case item
}

protocol RecentlyVisitedItem {
    var displayTitle: String { get }
    var description: String? { get }
    var siteUrl: URL? { get }
    var type: RecentlyVisitedItemType { get }
    var group: [RecentlyVisitedItem]? { get }
}

extension HistoryHighlight: RecentlyVisitedItem {

    var group: [RecentlyVisitedItem]? {
        return nil
    }

    var type: RecentlyVisitedItemType {
        return .item
    }

    var displayTitle: String {
        return title ?? url
    }

    var description: String? {
        return nil
    }

    var siteUrl: URL? {
        return URL(string: url)
    }
}
