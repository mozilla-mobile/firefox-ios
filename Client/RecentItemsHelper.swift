// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import Shared

protocol RecentlySavedItem {
    var title: String { get }
    var url: String { get }

    var numberOfDaysBeforeStale: Int { get }
    func getItemDate() -> Date
    func getNumberOfDays(calendar: Calendar, date: Date) -> Int
}

extension RecentlySavedItem {
    func getNumberOfDays(calendar: Calendar, date: Date) -> Int {
        return calendar.numberOfDaysBetween(getItemDate(), and: date)
    }
}

extension ReadingListItem: RecentlySavedItem {
    var numberOfDaysBeforeStale: Int { return 7 }

    func getItemDate() -> Date {
        // ReadingListItem is using timeIntervalSinceReferenceDate to save lastModified timestamp
        return Date(timeIntervalSinceReferenceDate: Double(lastModified) / 1000)
    }
}

extension BookmarkItemData: RecentlySavedItem {
    var numberOfDaysBeforeStale: Int { return 10 }

    func getItemDate() -> Date {
        return Date.fromTimestamp(Timestamp(dateAdded))
    }
}

class RecentItemsHelper {

    private let calendar = Calendar.current
    
    /// Filter `RecenlySavedItems` that are a older than a `numberOfDaysBeforeStale` count.
    /// - Parameters:
    ///   - recentItems: Items to filter.
    ///   - date: The date to filter against.
    /// - Returns: A filtered list of items that are within the cutoff date.
    func filterStaleItems(recentItems: [RecentlySavedItem], since date: Date = Date()) -> [RecentlySavedItem] {
        return recentItems.filter {
            return $0.getNumberOfDays(calendar: calendar, date: date) <= $0.numberOfDaysBeforeStale
        }
    }
}
