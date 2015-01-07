/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import CoreData
import UIKit

class Favicon {
    var url: String
    var image: UIImage?
    var updatedDate: NSDate
    var sites: NSSet

    init(url: String, image: UIImage?, updatedDate: NSDate, sites: NSSet) {
        self.url = url
        self.image = image
        self.updatedDate = NSDate()
        self.sites = NSSet()
    }
}

extension Favicon {
    func addSite(site: Site) {
    }

    func removeSite(site: Site) {
    }
}
