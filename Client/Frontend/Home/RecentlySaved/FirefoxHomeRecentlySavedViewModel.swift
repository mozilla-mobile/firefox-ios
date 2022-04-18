// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage

class FirefoxHomeRecentlySavedViewModel {

    // MARK: - Properties

    var isZeroSearch: Bool
    private let profile: Profile

    private lazy var siteImageHelper = SiteImageHelper(profile: profile)
    private var readingListItems = [ReadingListItem]()
    private var recentBookmarks = [BookmarkItemData]()
    private let recentItemsHelper = RecentItemsHelper()
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

    func getHeroImage(forSite site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
            completion(image)
        }
    }

    // MARK: - Reading list

    private func getReadingLists(group: DispatchGroup) {
        group.enter()
        let maxItems = RecentlySavedCollectionCellUX.readingListItemsLimit
        profile.readingList.getAvailableRecords().uponQueue(dataQueue, block: { [weak self] result in
            let items = result.successValue?.prefix(maxItems) ?? []
            self?.updateReadingList(readingList: Array(items))
            group.leave()
        })
    }

    private func updateReadingList(readingList: [ReadingListItem]) {
        readingListItems = recentItemsHelper.filterStaleItems(recentItems: readingList) as? [ReadingListItem] ?? []

        let extra = [TelemetryWrapper.EventObject.recentlySavedReadingItemImpressions.rawValue: "\(readingListItems.count)"]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .recentlySavedReadingListView,
                                     extras: extra)
    }

    // MARK: - Bookmarks

    private func getRecentBookmarks(group: DispatchGroup) {
        group.enter()
        profile.places.getRecentBookmarks(limit: RecentlySavedCollectionCellUX.bookmarkItemsLimit).uponQueue(dataQueue, block: { [weak self] result in
            self?.updateRecentBookmarks(bookmarks: result.successValue ?? [])
            group.leave()
        })
    }

    private func updateRecentBookmarks(bookmarks: [BookmarkItemData]) {
        recentBookmarks = recentItemsHelper.filterStaleItems(recentItems: bookmarks) as? [BookmarkItemData] ?? []

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

// MARK: FXHomeViewModelProtocol
extension FirefoxHomeRecentlySavedViewModel: FXHomeViewModelProtocol, FeatureFlagsProtocol {

    var sectionType: FirefoxHomeSectionType {
        return .recentlySaved
    }

    var isEnabled: Bool {
        return featureFlags.isFeatureActiveForBuild(.recentlySaved)
        && featureFlags.isFeatureActiveForNimbus(.recentlySaved)
        && featureFlags.userPreferenceFor(.recentlySaved) == UserFeaturePreference.enabled
    }

    var hasData: Bool {
        return !recentBookmarks.isEmpty || !readingListItems.isEmpty
    }

    /// Using dispatch group to know when data has completely loaded for both sources (recent bookmarks and reading list items)
    func updateData(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        getRecentBookmarks(group: group)
        getReadingLists(group: group)

        group.notify(queue: .main) {
            completion()
        }
    }
}
