// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum HomePanelType: Int {
    case topSites = 0

    var internalUrl: URL {
        let aboutUrl = URL(string: "\(InternalURL.baseUrl)/\(AboutHomeHandler.path)", invalidCharacters: false)!
        return URL(string: "#panel=\(self.rawValue)", relativeTo: aboutUrl)!
    }
}
