// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage

/// The filtered jumpBack in list to display to the user.
/// Only one group is displayed
struct JumpBackInList {
    let group: ASGroup<Tab>?
    let tabs: [Tab]
    var itemsToDisplay: Int {
        get {
            var count = 0

            count += group != nil ? 1 : 0
            count += tabs.count

            return count
        }
    }
}

class FirefoxHomeJumpBackInViewModel: FeatureFlagsProtocol {

    // MARK: - Properties
    var onTapGroup: ((Tab) -> Void)?
    var jumpBackInList = JumpBackInList(group: nil, tabs: [Tab]())

    private var recentTabs: [Tab] = [Tab]()
    private var recentGroups: [ASGroup<Tab>]?
    private let isZeroSearch: Bool
    private let profile: Profile
    private let tabManager: TabManager
    private lazy var siteImageHelper = SiteImageHelper(profile: profile)

    init(isZeroSearch: Bool = false,
         profile: Profile,
         tabManager: TabManager = BrowserViewController.foregroundBVC().tabManager) {

        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.tabManager = tabManager
    }

    // The dimension of a cell
    static var widthDimension: NSCollectionLayoutDimension {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .absolute(FxHomeHorizontalCellUX.cellWidth) // iPad
        } else if UIWindow.isLandscape {
            return .fractionalWidth(1/2) // iPhone in landscape
        } else {
            return .fractionalWidth(1) // iPhone in portrait
        }
    }

    // The maximum number of items to display in the whole section
    static var maxItemsToDisplay: Int {
        return UIDevice.current.userInterfaceIdiom == .pad ? 3 : UIWindow.isLandscape ? 4 : 2
    }

    static var maxNumberOfItemsInColumn: Int {
        return UIDevice.current.userInterfaceIdiom == .pad ? 1 : 2
    }

    var numberOfItemsInColumn: Int {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 1
        } else {
            return jumpBackInList.itemsToDisplay > 1 ? 2 : 1
        }
    }

    /// Update data with tab and search term group managers
    func updateData(completion: @escaping () -> Void) {
        recentTabs = tabManager.recentlyAccessedNormalTabs

        if featureFlags.isFeatureActiveForBuild(.groupedTabs),
           featureFlags.userPreferenceFor(.groupedTabs) == UserFeaturePreference.enabled {
            SearchTermGroupsManager.getTabGroups(with: profile,
                                                 from: recentTabs,
                                                 using: .orderedDescending) { [weak self] groups, _ in
                guard let strongSelf = self else { completion(); return }
                strongSelf.recentGroups = groups
                strongSelf.jumpBackInList = strongSelf.createJumpBackInList(from: strongSelf.recentTabs, and: groups)
                completion()
            }
        } else {
            jumpBackInList = createJumpBackInList(from: recentTabs)
            completion()
        }
    }

    /// Refresh data for new layout
    func refreshData() {
        jumpBackInList = createJumpBackInList(from: recentTabs, and: recentGroups)
    }

    func switchTo(group: ASGroup<Tab>) {
        if BrowserViewController.foregroundBVC().urlBar.inOverlayMode {
            BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode()
        }
        guard let firstTab = group.groupedItems.first else { return }

        onTapGroup?(firstTab)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .jumpBackInSectionGroupOpened,
                                     extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))
    }

    func switchTo(tab: Tab) {
        if BrowserViewController.foregroundBVC().urlBar.inOverlayMode {
            BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode()
        }
        tabManager.selectTab(tab)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .jumpBackInSectionTabOpened,
                                     extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))
    }

    func getFaviconImage(forSite site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .favicon, shouldFallback: false) { image in
            completion(image)
        }
    }

    func getHeroImage(forSite site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: false) { image in
            completion(image)
        }
    }

    // MARK: - Private

    private func createJumpBackInList(from tabs: [Tab], and groups: [ASGroup<Tab>]? = nil) -> JumpBackInList {
        let recentGroup = groups?.first
        let groupCount = recentGroup != nil ? 1 : 0
        let recentTabs = filter(tabs: tabs, from: recentGroup, usingGroupCount: groupCount)

        return JumpBackInList(group: recentGroup, tabs: recentTabs)
    }

    private func filter(tabs: [Tab], from recentGroup: ASGroup<Tab>?, usingGroupCount groupCount: Int) -> [Tab] {
        var recentTabs = [Tab]()
        let maxItemCount = FirefoxHomeJumpBackInViewModel.maxItemsToDisplay - groupCount

        for tab in tabs {
            // We must make sure to not include any 'solo' tabs that are also part of a group
            // because they should not show up in the Jump Back In section.
            if let recentGroup = recentGroup, recentGroup.groupedItems.contains(tab) { continue }

            recentTabs.append(tab)
            // We are only showing one group in Jump Back in, so adjust count accordingly
            if recentTabs.count == maxItemCount { break }
        }

        return recentTabs
    }
}
