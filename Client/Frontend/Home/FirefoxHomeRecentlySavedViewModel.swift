// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage

protocol RecentlySavedItem {
    var title: String { get }
    var url: String { get }
}

extension ReadingListItem: RecentlySavedItem { }
extension BookmarkItem: RecentlySavedItem { }

class FirefoxHomeRecentlySavedViewModel: CanSetHeroImage {
    
    // MARK: - Properties
    var profile: Profile!
    var isZeroSearch: Bool

    lazy var siteImageHelper = SiteImageHelper(profile: profile)

    private var readingListItems = [ReadingListItem]()
    private var recentBookmarks = [BookmarkItem]() {
        didSet {
            recentBookmarks = RecentItemsHelper.filterStaleItems(recentItems: recentBookmarks, since: Date()) as! [BookmarkItem]
        }
    }

    init(isZeroSearch: Bool, profile: Profile) {
        self.isZeroSearch = isZeroSearch
        self.profile = profile
    }

    var recentItems: [RecentlySavedItem] {
        var items = [RecentlySavedItem]()
        items.append(contentsOf: recentBookmarks)
        items.append(contentsOf: readingListItems)

        return items
    }

    /// Using dispatch group to know when data has completely loaded for both sourced (recent bookmarks and reading list items)
    func updateData(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        group.enter()
        profile.places.getRecentBookmarks(limit: RecentlySavedCollectionCellUX.bookmarkItemsLimit).uponQueue(.main, block: { [weak self] result in
            self?.recentBookmarks = result.successValue ?? []
            group.leave()
        })

        group.enter()
        if let readingList = profile.readingList.getAvailableRecords().value.successValue?.prefix(RecentlySavedCollectionCellUX.readingListItemsLimit) {
            let readingListItems = Array(readingList)
            self.readingListItems = RecentItemsHelper.filterStaleItems(recentItems: readingListItems, since: Date()) as! [ReadingListItem]
            group.leave()
        }

        group.notify(queue: .main) {
            completion()
        }
    }
}
