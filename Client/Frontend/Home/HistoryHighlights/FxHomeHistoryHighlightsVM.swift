/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class FxHomeHistoryHightlightsVM {

    // MARK: - Properties & Variables
    var historyItems = [Tab]()
    private var tabManager: TabManager
    private var foregroundBVC: BrowserViewController

    var onTapItem: (() -> Void)?

    private var recentTabs = [Tab]()
    private var maxItemsAllowed: Int {
        HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn * HistoryHighlightsCollectionCellConstants.maxNumberOfColumns
    }

    // MARK: - Inits
    init(with tabManager: TabManager = BrowserViewController.foregroundBVC().tabManager,
         foregroundBVC: BrowserViewController = BrowserViewController.foregroundBVC()) {
        self.tabManager = tabManager
        self.foregroundBVC = foregroundBVC
    }

    // MARK: - Public methods
    public func updateData() {
        loadItems()
    }

    public func switchTo() {
        if foregroundBVC.urlBar.inOverlayMode {
            foregroundBVC.urlBar.leaveOverlayMode()
        }
        onTapItem?()
//        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .firefoxHomepage, value: .jumpBackInSectionTabOpened)
    }

    // MARK: - Private Methods
    private func loadItems() {
        configureData()
        var items = [Tab]()

        items.append(contentsOf: recentTabs)

        historyItems.removeAll()

        for item in items {
            historyItems.append(item)
            if historyItems.count == maxItemsAllowed { break }
        }
    }

    private func configureData() {
        recentTabs.removeAll()
        recentTabs = tabManager.recentlyAccessedNormalTabs
    }
}
