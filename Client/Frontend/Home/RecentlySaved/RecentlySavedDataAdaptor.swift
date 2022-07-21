// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol RecentlySavedDataAdaptor {
    var recentItems: [RecentlySavedItem] { get }
    func getHeroImage(forSite site: Site) -> UIImage?
    func getRecentlySavedData() -> [RecentlySavedItem]
}

protocol RecentlySavedDelegate: AnyObject {
    func didLoadNewData()
}

class RecentlySavedDataAdaptorImplementation: RecentlySavedDataAdaptor, Notifiable {

    var notificationCenter: NotificationCenter
    private let bookmarkItemsLimit: UInt = 5
    private let readingListItemsLimit: Int = 5
    private let dataQueue = DispatchQueue(label: "com.moz.recentlySaved.queue")
    private let recentItemsHelper = RecentItemsHelper()
    private var siteImageHelper: SiteImageHelper
    private var profile: Profile
    private var recentBookmarks = [RecentlySavedBookmark]()
    private var readingListItems = [ReadingListItem]()
    private var heroImages = [String: UIImage]() {
        didSet {
            delegate?.didLoadNewData()
        }
    }

    var recentItems: [RecentlySavedItem] {
        var items = [RecentlySavedItem]()
        items.append(contentsOf: recentBookmarks)
        items.append(contentsOf: readingListItems)

        return items
    }

    weak var delegate: RecentlySavedDelegate?

    init(siteImageHelper: SiteImageHelper,
         profile: Profile,
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.siteImageHelper = siteImageHelper
        self.profile = profile
        self.notificationCenter = notificationCenter

        getRecentBookmarks()
        getReadingLists()
    }

    func getHeroImage(forSite site: Site) -> UIImage? {
        if let heroImage = heroImages[site.url] {
            return heroImage
        }
        siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
            self.heroImages[site.url] = image
        }
        return nil
    }

    func getRecentlySavedData() -> [RecentlySavedItem] {
        var items = [RecentlySavedItem]()
        items.append(contentsOf: recentBookmarks)
        items.append(contentsOf: readingListItems)

        return items
    }

    // MARK: - Bookmarks

    private func getRecentBookmarks() {
        profile.places.getRecentBookmarks(limit: bookmarkItemsLimit).uponQueue(dataQueue, block: { [weak self] result in
            let resultBookmarks: [BookmarkItemData] = result.successValue ?? []
            let bookmarks = resultBookmarks.map { RecentlySavedBookmark(bookmark: $0) }
            self?.updateRecentBookmarks(bookmarks: bookmarks)
        })
    }

    private func updateRecentBookmarks(bookmarks: [RecentlySavedBookmark]) {
        recentBookmarks = recentItemsHelper.filterStaleItems(recentItems: bookmarks) as? [RecentlySavedBookmark] ?? []
        delegate?.didLoadNewData()

        // Send telemetry if bookmarks aren't empty
        if !recentBookmarks.isEmpty {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedBookmarkItemView,
                                         extras: [TelemetryWrapper.EventObject.recentlySavedBookmarkImpressions.rawValue: "\(bookmarks.count)"])
        }
    }

    // MARK: - Reading list

    private func getReadingLists() {
        let maxItems = readingListItemsLimit
        profile.readingList.getAvailableRecords().uponQueue(dataQueue, block: { [weak self] result in
            let items = result.successValue?.prefix(maxItems) ?? []
            self?.updateReadingList(readingList: Array(items))
        })
    }

    private func updateReadingList(readingList: [ReadingListItem]) {
        readingListItems = recentItemsHelper.filterStaleItems(recentItems: readingList) as? [ReadingListItem] ?? []
        delegate?.didLoadNewData()

        let extra = [TelemetryWrapper.EventObject.recentlySavedReadingItemImpressions.rawValue: "\(readingListItems.count)"]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .recentlySavedReadingListView,
                                     extras: extra)
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .ReadingListUpdated:
            getReadingLists()
        case .BookmarksUpdated:
            getRecentBookmarks()
        default: break
        }
    }
}
