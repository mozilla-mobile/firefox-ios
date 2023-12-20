// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct InactiveTabsModel: Equatable {
    var tabUUID: String
    var title: String
    var url: URL?

    var displayURL: String {
        guard let url = url else { return title }

        return url.absoluteString
    }
}
