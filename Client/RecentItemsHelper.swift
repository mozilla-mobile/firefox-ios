/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

class RecentItemsHelper {
    
    /// Filter items that are a older than some number of days.
    /// - Parameters:
    ///
    ///   - recentItems: Items to filter.
    ///   - since: A specified number of days old.
    /// - Returns: A filtered list of items that are within the cutoff date.
    static func filterStaleItems(recentItems: [RecentlySavedItem], since: Int) -> [RecentlySavedItem] {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: since, to: Date()) else { return [] }
        
        if let bookmarkItem = recentItems as? [BookmarkItem] {
            return bookmarkItem.filter { item in
                let dateAdded = Date(timeIntervalSince1970: TimeInterval(item.dateAdded))
                return (dateAdded >= cutoffDate)
            }
        } else if let readingListitem = recentItems as? [ReadingListItem] {
            return readingListitem.filter { item in
                let lastModified = Date(timeIntervalSince1970: TimeInterval(item.lastModified))
                return lastModified >= cutoffDate
            }
        }
        
        return []
    }
    
}
