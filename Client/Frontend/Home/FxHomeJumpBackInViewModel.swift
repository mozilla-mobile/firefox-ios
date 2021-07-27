/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class FirefoxHomeJumpBackInViewModel {

    // MARK: - Properties
    var jumpableTabs = [Tab]()
    private var recentTabs = [Tab]()

    var layoutVariables: JumpBackInLayoutVariables
    var tabManager: TabManager

    init() {
        self.tabManager = BrowserViewController.foregroundBVC().tabManager
        self.layoutVariables = JumpBackInLayoutVariables(columns: 1, scrollDirection: .vertical, maxItemsToDisplay: 2)
    }

    public func updateDataAnd(_ layoutVariables: JumpBackInLayoutVariables) {
        self.layoutVariables = layoutVariables
        loadItems()
    }

    public func switchTo(_ tab: Tab) {
        if BrowserViewController.foregroundBVC().urlBar.inOverlayMode {
            BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode()
        }
        tabManager.selectTab(tab)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .firefoxHomepage, value: .jumpBackInSectionTabOpened)
    }

    // In the future, we may add `currentlyPlayingMedia` tabs to the Jump Back In section.
    // Here, we consolidate all sources into one array. Additional logic will be required
    // to determine which tabs to show when multiple tab sources will be put together.
    private func loadItems() {
        configureData()
        var items = [Tab]()

        items.append(contentsOf: recentTabs)

        jumpableTabs.removeAll()

        for tab in items {
            jumpableTabs.append(tab)
            if jumpableTabs.count >= layoutVariables.maxItemsToDisplay { break }
        }
    }

    private func configureData() {
        recentTabs.removeAll()
        recentTabs = tabManager.recentlyAccessedNormalTabs
    }
}
