// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import Shared

class RecentItemsHelper {
    
    /// Filter `RecenlySavedItems` that are a older than some number of days.
    /// Bookmarks and reading list items are stale after 10 days and 7 days, respectively.
    /// - Parameters:
    ///
    ///   - recentItems: Items to filter.
    ///   - since: The date to test against.
    /// - Returns: A filtered list of items that are within the cutoff date.
    static func filterStaleItems(recentItems: [RecentlySavedItem], since: Date = Date()) -> [RecentlySavedItem] {
        var cutoff = since
        let calendar = Calendar.current
        
        if let bookmarkItem = recentItems as? [BookmarkItemData] {
            return bookmarkItem.filter { item in
                let dateAdded = Date.fromTimestamp(Timestamp(item.dateAdded))
                return calendar.numberOfDaysBetween(dateAdded, and: cutoff) <= 10
            }
        } else if let readingListitem = recentItems as? [ReadingListItem] {
            return readingListitem.filter { item in
                let lastModified = Date.fromTimestamp(item.lastModified)
                
                // lastModified gives the incorrect year, so we need to
                // adjust our cutoff date's year to match that year.
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "YYYY"
                let yearString = dateFormatter.string(from: lastModified)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: cutoff)
                dateComponents.year = Int(yearString)
                cutoff = calendar.date(from: dateComponents)!
                
                return calendar.numberOfDaysBetween(lastModified, and: cutoff) <= 7
            }
        }
        
        return []
    }
    
}
