// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct InactiveTabsModel: Equatable, Identifiable, Hashable {
    var id: String { return tabUUID }
    let tabUUID: TabUUID
    let title: String
    let url: URL?
    var favIconURL: String?

    var displayURL: String {
        guard let url = url else { return title }

        return url.absoluteString
    }

    static func emptyState(
        tabUUID: TabUUID,
        title: String
    ) -> InactiveTabsModel {
        return InactiveTabsModel(
            tabUUID: tabUUID,
            title: title,
            url: nil
        )
    }
}
