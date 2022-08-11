// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol HistoryHighlightsDataAdaptor {
    var delegate: HistoryHighlightsDelegate? { get set }

    func getHistoryHightlights() -> [HighlightItem]
}

protocol HistoryHighlightsDelegate: AnyObject {
    func didLoadNewData()
}

class HistoryHighlightsDataAdaptorImplementation: HistoryHighlightsDataAdaptor {

    private var historyItems = [HighlightItem]()
    private var historyManager: HistoryHighlightsManagerProtocol
    private var profile: Profile
    private var tabManager: TabManagerProtocol
    var notificationCenter: NotificationProtocol
    weak var delegate: HistoryHighlightsDelegate?

    init(historyManager: HistoryHighlightsManagerProtocol = HistoryHighlightsManager(),
         profile: Profile,
         tabManager: TabManagerProtocol,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.historyManager = historyManager
        self.profile = profile
        self.tabManager = tabManager
        self.notificationCenter = notificationCenter

        setupNotifications(forObserver: self,
                           observing: [.HistoryUpdated])
        loadHistory()
    }

    func getHistoryHightlights() -> [HighlightItem] {
        return historyItems
    }

    private func loadHistory() {
        historyManager.getHighlightsData(
            with: profile,
            and: tabManager.tabs,
            shouldGroupHighlights: true) { [weak self] highlights in

                self?.historyItems = highlights ?? []
                self?.delegate?.didLoadNewData()
        }
    }
}

extension HistoryHighlightsDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .HistoryUpdated:
            loadHistory()
        default:
            return
        }
    }
}
