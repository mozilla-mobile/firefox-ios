/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import CoreData

@objc(Favicon)
class Favicon: NSManagedObject {
    @NSManaged var url: String
    @NSManaged var image: AnyObject
    @NSManaged var updatedDate: NSDate
    @NSManaged var sites: NSSet
}

extension Favicon {
    func addSite(site: Site) {
        var items = self.mutableSetValueForKey("sites");
        items.addObject(site)
    }

    func removeSite(site: Site) {
        var items = self.mutableSetValueForKey("sites");
        items.removeObject(site)
    }
}
