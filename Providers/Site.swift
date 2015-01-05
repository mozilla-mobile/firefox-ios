/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import CoreData

class Site {
    var url: String
    var title: String
    var favicons: NSSet

    init(url: String, title: String, favicons: NSSet) {
        self.url = url
        self.title = title
        self.favicons = favicons
    }
}

extension Site {
    func addFavicon(favicon: Favicon) {
    }

    func removeFavicon(favicon: Favicon) {
    }
}
