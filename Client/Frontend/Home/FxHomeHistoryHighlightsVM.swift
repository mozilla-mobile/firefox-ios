/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class FxHomeHistoryHightlightsVM {

    // MARK: - Properties
    var historyItems = [Tab]()

    private var recentTabs = [Tab]()
    private var maxItemsAllowed = 9

    var tabManager: TabManager

    init() {
        self.tabManager = BrowserViewController.foregroundBVC().tabManager
    }

    public func updateData() {
        loadItems()
    }

    public func switchTo(_ tab: Tab) {
        if BrowserViewController.foregroundBVC().urlBar.inOverlayMode {
            BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode()
        }
        tabManager.selectTab(tab)
//        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .firefoxHomepage, value: .jumpBackInSectionTabOpened)
    }

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
