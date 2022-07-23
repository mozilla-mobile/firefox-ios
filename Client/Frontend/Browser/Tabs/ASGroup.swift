// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct ASGroup<T>: Hashable {
    var searchTerm: String
    var groupedItems: [T]
    var timestamp: Timestamp
    let identifier = UUID()

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: ASGroup<T>, rhs: ASGroup<T>) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension ASGroup: HighlightItem {
    var group: [HighlightItem]? {
        groupedItems as? [HighlightItem]
    }

    var type: HighlightItemType {
        .group
    }

    var displayTitle: String {
        searchTerm
    }

    var description: String? {
        String.localizedStringWithFormat(.FirefoxHomepage.Common.SitesCount, groupedItems.count)
    }

    var siteUrl: URL? {
        nil
    }
}
