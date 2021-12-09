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

class FirefoxHomeRecentlySavedViewModel {
    
    // MARK: - Properties

    var isZeroSearch: Bool

    private let profile: Profile
    private lazy var siteImageHelper = SiteImageHelper(profile: profile)
    private var readingListItems = [ReadingListItem]()
    private var recentBookmarks = [BookmarkItem]()
    private let dataQueue = DispatchQueue(label: "com.moz.recentlySaved.queue")

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

    // Whether the section is has data to show or not
    var hasData: Bool {
        return !recentBookmarks.isEmpty || !readingListItems.isEmpty
    }

    /// Using dispatch group to know when data has completely loaded for both sources (recent bookmarks and reading list items)
    func updateData(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        group.enter()
        profile.places.getRecentBookmarks(limit: RecentlySavedCollectionCellUX.bookmarkItemsLimit).uponQueue(dataQueue, block: { [weak self] result in
            self?.updateRecentBookmarks(bookmarks: result.successValue ?? [])
            group.leave()
        })

        group.enter()
        let maxItems = RecentlySavedCollectionCellUX.readingListItemsLimit
        if let readingList = profile.readingList.getAvailableRecords().value.successValue?.prefix(maxItems) {
            readingListItems = RecentItemsHelper.filterStaleItems(recentItems: Array(readingList), since: Date()) as! [ReadingListItem]

            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedReadingListView,
                                         extras: [TelemetryWrapper.EventObject.recentlySavedReadingItemImpressions.rawValue: "\(readingListItems.count)"])
            group.leave()
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    func getHeroImage(forSite site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
            completion(image)
        }
    }

    // MARK: - Private

    private func updateRecentBookmarks(bookmarks: [BookmarkItem]) {
        recentBookmarks = RecentItemsHelper.filterStaleItems(recentItems: bookmarks, since: Date()) as! [BookmarkItem]

        // Send telemetry if bookmarks aren't empty
        if !recentBookmarks.isEmpty {

            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedBookmarkItemView,
                                         extras: [TelemetryWrapper.EventObject.recentlySavedBookmarkImpressions.rawValue: "\(bookmarks.count)"])
        }
    }
}
