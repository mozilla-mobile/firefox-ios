// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol RecentlyVisitedDataAdaptor {
    var delegate: RecentlyVisitedDelegate? { get set }

    func getRecentlyVisited() -> [RecentlyVisitedItem]
    func delete(_ item: RecentlyVisitedItem)
}

protocol RecentlyVisitedDelegate: AnyObject {
    func didLoadNewData()
}

class RecentlyVisitedDataAdaptorImplementation: RecentlyVisitedDataAdaptor {

    private var historyItems = [RecentlyVisitedItem]()
    private var historyManager: RecentlyVisitedManagerProtocol
    private var profile: Profile
    private var tabManager: TabManagerProtocol
    private var deletionUtility: HistoryDeletionProtocol
    var notificationCenter: NotificationProtocol
    weak var delegate: RecentlyVisitedDelegate?

    init(historyManager: RecentlyVisitedManagerProtocol = RecentlyVisitedManager(),
         profile: Profile,
         tabManager: TabManagerProtocol,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         deletionUtility: HistoryDeletionProtocol) {
        self.historyManager = historyManager
        self.profile = profile
        self.tabManager = tabManager
        self.notificationCenter = notificationCenter
        self.deletionUtility = deletionUtility

        setupNotifications(forObserver: self,
                           observing: [.HistoryUpdated,
                                       .RustPlacesOpened])
        loadHistory()
    }

    func getRecentlyVisited() -> [RecentlyVisitedItem] {
        return historyItems
    }

    func delete(_ item: RecentlyVisitedItem) {
        let urls = extractDeletableURLs(from: item)

        deletionUtility.delete(urls) { [weak self] successful in
            if successful { self?.loadHistory() }
        }
    }

    // MARK: - Private Methods

    private func loadHistory() {
        historyManager.getData(
            with: profile,
            and: tabManager.tabs,
            shouldGroup: true) { [weak self] highlights in

                self?.historyItems = highlights ?? []
                self?.delegate?.didLoadNewData()
        }
    }

    private func extractDeletableURLs(from item: RecentlyVisitedItem) -> [String] {
        var urls = [String]()
        if item.type == .item, let url = item.siteUrl?.absoluteString {
            urls = [url]

        } else if item.type == .group, let items = item.group {
            items.forEach { groupedItem in
                if let url = groupedItem.siteUrl?.absoluteString { urls.append(url) }
            }
        }

        return urls
    }
}

extension RecentlyVisitedDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .HistoryUpdated,
                .RustPlacesOpened:
            loadHistory()
        default:
            return
        }
    }
}
