// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

class SearchGroupedItemsViewModel {
    // MARK: - Properties

    var asGroup: ASGroup<Site>
    var presenter: Presenter

    /// There are two entry points into this VC
    enum Presenter {
        case historyPanel
        case recentlyVisited
    }

    // MARK: - Inits

    init(asGroup: ASGroup<Site>, presenter: Presenter) {
        self.asGroup = asGroup
        self.presenter = presenter
    }
}
