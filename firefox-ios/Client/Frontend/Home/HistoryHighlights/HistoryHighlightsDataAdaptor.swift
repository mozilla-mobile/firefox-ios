// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol HistoryHighlightsDataAdaptor {
    var delegate: HistoryHighlightsDelegate? { get set }

    func getHistoryHighlights() -> [HighlightItem]
    func delete(_ item: HighlightItem)
}

protocol HistoryHighlightsDelegate: AnyObject {
    func didLoadNewData()
}

class HistoryHighlightsDataAdaptorImplementation: HistoryHighlightsDataAdaptor, FeatureFlaggable {
    private var historyItems = [HighlightItem]()
    private var historyManager: HistoryHighlightsManagerProtocol
    private var profile: Profile
    private var tabManager: TabManager
    private var deletionUtility: HistoryDeletionProtocol
    var notificationCenter: NotificationProtocol
    weak var delegate: HistoryHighlightsDelegate?

    init(historyManager: HistoryHighlightsManagerProtocol = HistoryHighlightsManager(),
         profile: Profile,
         tabManager: TabManager,
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

    func getHistoryHighlights() -> [HighlightItem] {
        return historyItems
    }

    func delete(_ item: HighlightItem) {
        let urls = extractDeletableURLs(from: item)

        deletionUtility.delete(urls) { [weak self] successful in
            if successful { self?.loadHistory() }
        }
    }

    // MARK: - Private Methods

    private func loadHistory() {
        historyManager.getHighlightsData(
            with: profile,
            and: tabManager.tabs,
            shouldGroupHighlights: true) { [weak self] highlights in
                self?.historyItems = highlights ?? []
                self?.delegate?.didLoadNewData()
        }
    }

    private func extractDeletableURLs(from item: HighlightItem) -> [String] {
        var urls = [String]()
        if item.type == .item, let url = item.urlString {
            urls = [url]
        } else if item.type == .group, let items = item.group {
            items.forEach { groupedItem in
                if let url = groupedItem.urlString { urls.append(url) }
            }
        }

        return urls
    }
}

extension HistoryHighlightsDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .HistoryUpdated,
                .RustPlacesOpened:
            // FXIOS-8107: Disabling loadHistory as it is causing the app to slow down on frequent calls
            // "recent-explorations" in homescreenFeature.yaml has been set to false for all builds
            if featureFlags.isFeatureEnabled(.historyHighlights, checking: .buildOnly) {
                loadHistory()
            }
        default:
            return
        }
    }
}
