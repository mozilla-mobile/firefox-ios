/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import UIKit

class FxHomeHistoryHightlightsVM {

    // MARK: - Properties & Variables
    var historyItems: [HighlightItem]?
    private var profile: Profile
    private var tabManager: TabManager
    private var foregroundBVC: BrowserViewController
    private lazy var siteImageHelper = SiteImageHelper(profile: profile)

    var onTapItem: (() -> Void)?

    private var recentTabs = [Tab]()
    private var maxItemsAllowed: Int {
        HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn * HistoryHighlightsCollectionCellConstants.maxNumberOfColumns
    }

    // MARK: - Inits
    init(with profile: Profile,
         tabManager: TabManager = BrowserViewController.foregroundBVC().tabManager,
         foregroundBVC: BrowserViewController = BrowserViewController.foregroundBVC()) {
        self.profile = profile
        self.tabManager = tabManager
        self.foregroundBVC = foregroundBVC

        loadItems()
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

    // good candidate for protocol because is used in JumpBackIn and here
    func getFavIcon(for site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .favicon, shouldFallback: false) { image in
            completion(image)
        }
    }

    // MARK: - Private Methods

    private func loadItems() {
        print("YRD loadItems hightlights")

        HistoryHighlightsManager.getHighlightsData(with: profile, and: tabManager.tabs) { [weak self] highlights in
            self?.historyItems = highlights
        }
    }

    private func configureData() {
        recentTabs.removeAll()
        recentTabs = tabManager.recentlyAccessedNormalTabs
    }
}
