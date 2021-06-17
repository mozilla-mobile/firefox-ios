/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

class BookmarksHelper {

    /// Filters bookmarks that are more than a specified number of days old.
    /// - Parameters:
    /// 
    ///   - bookmarks: Bookmarks retrieved from MozillaAppServices.
    ///   - since: The number of days the cutoff should be.
    /// - Returns: Bookmarks that have been added later than the cutoff date.
    static func filterOldBookmarks(bookmarks: [BookmarkNode], since: Int) -> [BookmarkNode] {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: since, to: Date()) else { return [] }
        
        return bookmarks.filter { item in
            let dateAdded = Date(timeIntervalSince1970: TimeInterval(item.dateAdded))
            return (dateAdded >= cutoffDate)
        }
    }
    
}
