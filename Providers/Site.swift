/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import CoreData

@objc(Site)
class Site: NSManagedObject {
    @NSManaged var url: String
    @NSManaged var title: String
    @NSManaged var favicons: NSSet
}

extension Site {
    func addFavicon(favicon: Favicon) {
        println("Add favicon \(favicon)")
        var items = self.mutableSetValueForKey("favicons");
        items.addObject(favicon)
        favicons = items
    }

    func removeFavicon(favicon: Favicon) {
        println("Remove favicon \(favicon)")
        var items = self.mutableSetValueForKey("favicons");
        items.removeObject(favicon)
        favicons = items
    }
}
