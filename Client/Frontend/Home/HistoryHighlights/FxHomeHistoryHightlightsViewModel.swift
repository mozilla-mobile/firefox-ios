/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import UIKit

class FxHomeHistoryHightlightsViewModel {

    // MARK: - Properties & Variables
    var historyItems: [HighlightItem]?
    private var profile: Profile
    private var isPrivate: Bool
    private var tabManager: TabManager
    private var foregroundBVC: BrowserViewController
    private lazy var siteImageHelper = SiteImageHelper(profile: profile)
    private var hasSentSectionEvent = false

    var onTapItem: ((HighlightItem) -> Void)?

    // MARK: - Variables
    /// We calculate the number of columns dynamically based on the numbers of items
    /// available such that we always have the appropriate number of columns for the
    /// rest of the dynamic calculations.
    var numberOfColumns: Int {
        guard let count = historyItems?.count else { return 0 }

        return Int(ceil(Double(count) / Double(HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn)))
    }

    var numberOfRows: Int {
        guard let count = historyItems?.count else { return 0 }

        return count < HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn ? count : HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn
    }

    /// Group weight used to create collection view compositional layout
    /// Case 1: For compact and a single column use 0.9 to ocuppy must of the width of the parent
    /// Case 2: For compact and multiple columns 0.8 to show part of the next column
    /// Case 3: For ipad we use 1/3 of the available width
    var groupWidthWeight: NSCollectionLayoutDimension {
        let groupWidth: NSCollectionLayoutDimension
        if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
            let weight = numberOfColumns == 1 ? 0.9 : 0.8
            groupWidth = NSCollectionLayoutDimension.fractionalWidth(weight)
        } else {
            groupWidth = NSCollectionLayoutDimension.fractionalWidth(1/3)
        }
        return groupWidth
    }

    // MARK: - Inits
    init(with profile: Profile,
         isPrivate: Bool,
         tabManager: TabManager = BrowserViewController.foregroundBVC().tabManager,
         foregroundBVC: BrowserViewController = BrowserViewController.foregroundBVC()) {
        self.profile = profile
        self.isPrivate = isPrivate
        self.tabManager = tabManager
        self.foregroundBVC = foregroundBVC

        loadItems() {}
    }

    // MARK: - Public methods

    func recordSectionHasShown() {
        if !hasSentSectionEvent {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .historyImpressions,
                                         value: nil,
                                         extras: nil)
            hasSentSectionEvent = true
        }
    }

    func switchTo(_ highlight: HighlightItem) {
        if foregroundBVC.urlBar.inOverlayMode {
            foregroundBVC.urlBar.leaveOverlayMode()
        }
        onTapItem?(highlight)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .firefoxHomepage, value: .historyHighlightsItemOpened)
    }

    // TODO: Good candidate for protocol because is used in JumpBackIn and here
    func getFavIcon(for site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .favicon, shouldFallback: false) { image in
            completion(image)
        }
    }

    // MARK: - Private Methods

    private func loadItems(completion: @escaping () -> Void) {
        HistoryHighlightsManager.getHighlightsData(with: profile,
                                                   and: tabManager.tabs,
                                                   shouldGroupHighlights: true) { [weak self] highlights in
            self?.historyItems = highlights
            completion()
        }
    }
}

// MARK: FXHomeViewModelProtocol
extension FxHomeHistoryHightlightsViewModel: FXHomeViewModelProtocol, FeatureFlagsProtocol {

    var sectionType: FirefoxHomeSectionType {
        return .historyHighlights
    }

    var isEnabled: Bool {
        guard featureFlags.isFeatureActiveForBuild(.historyHighlights),
              featureFlags.isFeatureActiveForNimbus(.historyHighlights),
              featureFlags.userPreferenceFor(.historyHighlights) == UserFeaturePreference.enabled
        else { return false }

        return !isPrivate
    }

    var hasData: Bool {
        return !(historyItems?.isEmpty ?? true)
    }

    func updateData(completion: @escaping () -> Void) {
        loadItems(completion: completion)
    }

    var shouldReloadSection: Bool { return true }

    func updatePrivacyConcernedSection(isPrivate: Bool) {
        self.isPrivate = isPrivate
    }
}
