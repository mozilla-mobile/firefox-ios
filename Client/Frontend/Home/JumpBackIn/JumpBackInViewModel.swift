// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import UIKit

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

/// The filtered jumpBack in synced tab to display to the user.
struct JumpBackInSyncedTab {
    let client: RemoteClient
    let tab: RemoteTab
}

class JumpBackInViewModel: FeatureFlaggable {

    struct UX {
        static let jumpBackInCellHeight: CGFloat = 112
        static let syncedTabCellHeight: CGFloat = 232
        static let maxDisplayedSyncedTabs: Int = 1
        static let maxJumpBackInItemsPerGroup: Int = 2
        static let interGroupSpacing: CGFloat = 14
        static let nestedGroupInterItemSpacing = NSCollectionLayoutSpacing.fixed(14)
    }

    enum DisplayGroup {
        case jumpBackIn
        case syncedTab
    }

    // MARK: - Properties
    var headerButtonAction: ((UIButton) -> Void)?
    var onTapGroup: ((Tab) -> Void)?

    weak var browserBarViewDelegate: BrowserBarViewDelegate?

    var jumpBackInList = JumpBackInList(group: nil, tabs: [Tab]())
    var mostRecentSyncedTab: JumpBackInSyncedTab?

    private var recentTabs: [Tab] = [Tab]()
    private lazy var siteImageHelper = SiteImageHelper(profile: profile)

    private var recentGroups: [ASGroup<Tab>]?

    private let isZeroSearch: Bool
    private let profile: Profile
    private var isPrivate: Bool
    private var hasSentJumpBackInSectionEvent = false
    private let tabManager: TabManagerProtocol

    init(
        isZeroSearch: Bool = false,
        profile: Profile,
        isPrivate: Bool,
        tabManager: TabManagerProtocol = BrowserViewController.foregroundBVC().tabManager
    ) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.isPrivate = isPrivate
        self.isPrivate = isPrivate
        self.tabManager = tabManager
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

    func switchTo(group: ASGroup<Tab>) {
        guard let delegate = browserBarViewDelegate else { return }

        if delegate.inOverlayMode {
            delegate.leaveOverlayMode(didCancel: false)
        }

        guard let firstTab = group.groupedItems.first else { return }

        onTapGroup?(firstTab)

        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .firefoxHomepage,
            value: .jumpBackInSectionGroupOpened,
            extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        )
    }

    func switchTo(tab: Tab) {
        guard let delegate = browserBarViewDelegate else { return }

        if delegate.inOverlayMode {
            delegate.leaveOverlayMode(didCancel: false)
        }

        tabManager.selectTab(tab, previous: nil)
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .firefoxHomepage,
            value: .jumpBackInSectionTabOpened,
            extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        )
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

    func sendImpressionTelemetry() {
        if !hasSentJumpBackInSectionEvent {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .jumpBackInImpressions,
                                         value: nil,
                                         extras: nil)
            hasSentJumpBackInSectionEvent = true
        }
    }
}

// MARK: - Private
private extension JumpBackInViewModel {

    var hasAccount: Bool {
        return profile.hasSyncableAccount() &&
                featureFlags.isFeatureEnabled(.jumpBackInSyncedTab, checking: .buildOnly)
    }

    var hasSyncedTab: Bool {
        return hasAccount && mostRecentSyncedTab != nil
    }

    func isSyncedTabCell(for index: IndexPath, traitCollection: UITraitCollection) -> Bool {
        return hasSyncedTab && ((index.row == 0 && traitCollection.horizontalSizeClass == .regular) ||
                              (index.row == 1 && traitCollection.horizontalSizeClass == .compact))
    }

    // The maximum number of items to display in the whole section
    func maxItemsToDisplay(for traitCollection: UITraitCollection, displayGroup: DisplayGroup) -> Int {
        switch displayGroup {
        case .jumpBackIn:
            return maxJumpBackInItemsToDisplay(for: traitCollection)
        case .syncedTab:
            return hasAccount ? JumpBackInViewModel.UX.maxDisplayedSyncedTabs : 0
        }
    }

    // The maximum number of items to display in the whole section
    func maxJumpBackInItemsToDisplay(for traitCollection: UITraitCollection) -> Int {
        if traitCollection.horizontalSizeClass == .compact, UIWindow.isPortrait {
            // iPhone in portrait
            return hasAccount ? 1 : 2
        } else if traitCollection.horizontalSizeClass == .compact {
            // iPhone (not plus size) in landscape
            return hasAccount ? 2 : 4
        } else if traitCollection.horizontalSizeClass == .regular, UIDevice.current.userInterfaceIdiom == .pad {
            // iPad
            return hasAccount ? 4 : 6
        } else {
            // iPhone Plus in landscape
            return hasAccount ? 2 : 4
        }

        // ToDo: figure out iPad in split view 1/2
//        return hasAccount ? 4 : 6
    }

    func indexOfJumpBackInItem(for indexPath: IndexPath, traitCollection: UITraitCollection) -> Int {
        // without synced tab the index stays the same as row
        guard hasSyncedTab else { return indexPath.row }

        // for regular size class the synced tab cell comes first
        if traitCollection.horizontalSizeClass == .regular {
            return indexPath.row - 1
        }

        return indexPath.row
    }

    func createJumpBackInList(
        from tabs: [Tab],
        withMaxItemsToDisplay maxItems: Int,
        and groups: [ASGroup<Tab>]? = nil
    ) -> JumpBackInList {
        let recentGroup = groups?.first
        let groupCount = recentGroup != nil ? 1 : 0
        let recentTabs = filter(
            tabs: tabs,
            from: recentGroup,
            usingGroupCount: groupCount,
            withMaxItemsToDisplay: maxItems
        )

        return JumpBackInList(group: recentGroup, tabs: recentTabs)
    }

    func filter(
        tabs: [Tab],
        from recentGroup: ASGroup<Tab>?,
        usingGroupCount groupCount: Int,
        withMaxItemsToDisplay maxItemsToDisplay: Int
    ) -> [Tab] {
        var recentTabs = [Tab]()
        let maxItemCount = maxItemsToDisplay - groupCount

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

    /// Update data with tab and search term group managers, saving it in view model for further usage
    func updateJumpBackInData(completion: @escaping () -> Void) {
        recentTabs = tabManager.recentlyAccessedNormalTabs

        if featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildAndUser) {
            SearchTermGroupsUtility.getTabGroups(
                with: profile,
                from: recentTabs,
                using: .orderedDescending
            ) { [weak self] groups, _ in
                guard let strongSelf = self else { completion(); return }

                strongSelf.recentGroups = groups
                completion()
            }
        } else {
            completion()
        }
    }

    func updateRemoteTabs(completion: @escaping () -> Void) {
        // Short circuit if the user is not logged in or feature not enabled
        guard hasAccount else {
            mostRecentSyncedTab = nil
            completion()
            return
        }

        // Get cached tabs

        DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
            self.profile.getCachedClientsAndTabs().uponQueue(.global(qos: .userInteractive)) { result in
                guard let clientAndTabs = result.successValue, clientAndTabs.count > 0 else {
                    self.mostRecentSyncedTab = nil
                    completion()
                    return
                }
                self.createMostRecentSyncedTab(from: clientAndTabs, completion: completion)
            }
        }
    }

    private func createMostRecentSyncedTab(from clientAndTabs: [ClientAndTabs], completion: @escaping () -> Void) {
        // filter clients for non empty desktop clients
        let desktopClientAndTabs = clientAndTabs.filter { $0.tabs.count > 0 &&
            ClientType.fromFxAType($0.client.type) == .Desktop }

        guard !desktopClientAndTabs.isEmpty else {
            mostRecentSyncedTab = nil
            completion()
            return
        }

        // get most recent tab
        var mostRecentTab: (client: RemoteClient, tab: RemoteTab)?

        desktopClientAndTabs.forEach { remoteClient in
            guard let firstClient = remoteClient.tabs.first else { return }
            let mostRecentClientTab = remoteClient.tabs.reduce(firstClient, {
                                                                $0.lastUsed > $1.lastUsed ? $0 : $1 })

            if let currentMostRecentTab = mostRecentTab,
               currentMostRecentTab.tab.lastUsed < mostRecentClientTab.lastUsed {
                mostRecentTab = (client: remoteClient.client, tab: mostRecentClientTab)
            } else if mostRecentTab == nil {
                mostRecentTab = (client: remoteClient.client, tab: mostRecentClientTab)
            }
        }

        guard let mostRecentTab = mostRecentTab else {
            mostRecentSyncedTab = nil
            completion()
            return
        }

        mostRecentSyncedTab = JumpBackInSyncedTab(client: mostRecentTab.client, tab: mostRecentTab.tab)
        completion()
    }

    func configureJumpBackInCellForGroups(group: ASGroup<Tab>, cell: HomeHorizontalCell, indexPath: IndexPath) {
        let firstGroupItem = group.groupedItems.first
        let site = Site(url: firstGroupItem?.lastKnownUrl?.absoluteString ?? "", title: firstGroupItem?.lastTitle ?? "")

        let descriptionText = String.localizedStringWithFormat(.FirefoxHomepage.JumpBackIn.GroupSiteCount, group.groupedItems.count)
        let faviconImage = UIImage(imageLiteralResourceName: ImageIdentifiers.stackedTabsIcon).withRenderingMode(.alwaysTemplate)
        let cellViewModel = FxHomeHorizontalCellViewModel(titleText: group.searchTerm.localizedCapitalized,
                                                          descriptionText: descriptionText,
                                                          tag: indexPath.item,
                                                          hasFavicon: true,
                                                          favIconImage: faviconImage)
        cell.configure(viewModel: cellViewModel)

        getHeroImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }
            cell.heroImage.image = image
        }
    }

    func configureJumpBackInCellForTab(item: Tab, cell: HomeHorizontalCell, indexPath: IndexPath) {
        let itemURL = item.lastKnownUrl?.absoluteString ?? ""
        let site = Site(url: itemURL, title: item.displayTitle)
        let descriptionText = site.tileURL.shortDisplayString.capitalized

        let cellViewModel = FxHomeHorizontalCellViewModel(titleText: site.title,
                                                          descriptionText: descriptionText,
                                                          tag: indexPath.item,
                                                          hasFavicon: true)
        cell.configure(viewModel: cellViewModel)

        /// Sets a small favicon in place of the hero image in case there's no hero image
        getFaviconImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }
            cell.faviconImage.image = image

            if cell.heroImage.image == nil {
                cell.fallbackFaviconImage.image = image
            }
        }

        /// Replace the fallback favicon image when it's ready or available
        getHeroImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }

            // If image is a square use it as a favicon
            if image?.size.width == image?.size.height {
                cell.fallbackFaviconImage.image = image
                return
            }

            cell.setFallBackFaviconVisibility(isHidden: true)
            cell.heroImage.image = image
        }
    }
}

// MARK: HomeViewModelProtocol
extension JumpBackInViewModel: HomepageViewModelProtocol {

    var sectionType: HomepageSectionType {
        return .jumpBackIn
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return LabelButtonHeaderViewModel(trailingInset: 0,
                                          title: HomepageSectionType.jumpBackIn.title,
                                          titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.jumpBackIn,
                                          isButtonHidden: false,
                                          buttonTitle: .RecentlySavedShowAllText,
                                          buttonAction: headerButtonAction,
                                          buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn)
    }

    var isEnabled: Bool {
        guard featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildAndUser) else { return false }

        return !isPrivate
    }

    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int {
        refreshData(for: traitCollection)
        return jumpBackInList.itemsToDisplay + (hasSyncedTab ? JumpBackInViewModel.UX.maxDisplayedSyncedTabs : 0)
    }

    // The width dimension of a cell / group; takes into account how many groups will be displayed
    func widthDimension(for traitCollection: UITraitCollection) -> NSCollectionLayoutDimension {
        if traitCollection.horizontalSizeClass == .compact && UIWindow.isPortrait {
            return .fractionalWidth(1) // iPhone in portrait
        } else if (traitCollection.horizontalSizeClass == .compact && UIWindow.isLandscape) ||
                    (traitCollection.horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .phone) {
            return .fractionalWidth(7.8/16) // iPhone in landscape
        } else {
            return .fractionalWidth(7.66/24) // iPad
        }
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        var section: NSCollectionLayoutSection

        if hasSyncedTab, traitCollection.horizontalSizeClass == .compact {
            section = sectionWithSyncedTabCompact(for: traitCollection)
        } else if hasSyncedTab {
            section = sectionWithSyncedTabRegular(for: traitCollection)
        } else {
            section = sectionWithoutSyncedTab(for: traitCollection)
        }

        // Supplementary Item
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                heightDimension: .estimated(34))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]

        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: leadingInset,
                                                        bottom: HomepageViewModel.UX.spacingBetweenSections,
                                                        trailing: leadingInset)
        section.interGroupSpacing = HomeHorizontalCell.UX.interGroupSpacing

        return section
    }

    private func sectionWithoutSyncedTab(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(JumpBackInViewModel.UX.jumpBackInCellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let nestedGroupWidth = widthDimension(for: traitCollection)
        let nestedGroupSize = NSCollectionLayoutSize(widthDimension: nestedGroupWidth,
                                                     heightDimension: .fractionalHeight(1))
        let nestedGroup = NSCollectionLayoutGroup.vertical(layoutSize: nestedGroupSize,
                                                           subitems: [item, item])
        nestedGroup.interItemSpacing = HomeHorizontalCell.UX.interItemSpacing

        let maxJumpBackInPerGroup = JumpBackInViewModel.UX.maxJumpBackInItemsPerGroup
        let groupHeight: CGFloat = JumpBackInViewModel.UX.jumpBackInCellHeight * CGFloat(maxJumpBackInPerGroup) +
                                    HomeHorizontalCell.UX.interItemSpacing.spacing
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(groupHeight))

        let numberOfItems = numberOfItemsInSection(for: traitCollection)
        let numberOfGroups = ceil(Double(numberOfItems) / Double(maxJumpBackInPerGroup))
        let subItems = Array(repeating: nestedGroup, count: Int(numberOfGroups))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: subItems)
        group.interItemSpacing = JumpBackInViewModel.UX.nestedGroupInterItemSpacing

        return NSCollectionLayoutSection(group: group)
    }

    // compact layout with synced tab
    private func sectionWithSyncedTabCompact(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        // Items
        let syncedTabItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(JumpBackInViewModel.UX.syncedTabCellHeight))
        let syncedTabItem = NSCollectionLayoutItem(layoutSize: syncedTabItemSize)

        let jumpBackInItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(JumpBackInViewModel.UX.jumpBackInCellHeight))
        let jumpBackInItem = NSCollectionLayoutItem(layoutSize: jumpBackInItemSize)

        // Main Group
        let groupWidth = widthDimension(for: traitCollection)
        let groupHeight: CGFloat = JumpBackInViewModel.UX.syncedTabCellHeight +
                                    JumpBackInViewModel.UX.jumpBackInCellHeight +
                                    HomeHorizontalCell.UX.interItemSpacing.spacing
        let groupSize = NSCollectionLayoutSize(widthDimension: groupWidth,
                                               heightDimension: .estimated(groupHeight))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize,
                                                     subitems: [jumpBackInItem, syncedTabItem])
        group.interItemSpacing = HomeHorizontalCell.UX.interItemSpacing

        return NSCollectionLayoutSection(group: group)
    }

    private func sectionWithSyncedTabRegular(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        // iPhone landscape

        let groupWidth = widthDimension(for: traitCollection)

        // Items
        let syncedTabItemSize = NSCollectionLayoutSize(
            widthDimension: groupWidth,
            heightDimension: .estimated(JumpBackInViewModel.UX.syncedTabCellHeight))
        let syncedTabItem = NSCollectionLayoutItem(layoutSize: syncedTabItemSize)

        let jumpBackInItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(JumpBackInViewModel.UX.jumpBackInCellHeight))
        let jumpBackInItem = NSCollectionLayoutItem(layoutSize: jumpBackInItemSize)

        // Nested Trailing Group (Jump Back In)
        let trailingGroupSize = NSCollectionLayoutSize(widthDimension: groupWidth,
                                                       heightDimension: .fractionalHeight(1))
        let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: trailingGroupSize,
                                                             subitems: [jumpBackInItem, jumpBackInItem])
        trailingGroup.interItemSpacing = HomeHorizontalCell.UX.interItemSpacing

        // Main Group
        let mainGroupHeight: CGFloat = JumpBackInViewModel.UX.syncedTabCellHeight
        let mainGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(mainGroupHeight))

        let maxJumpBackInPerGroup = JumpBackInViewModel.UX.maxJumpBackInItemsPerGroup
        let jumpBackInItems = jumpBackInList.itemsToDisplay
        let numberOfGroups = ceil(Double(jumpBackInItems) / Double(maxJumpBackInPerGroup))
        var subItems: [NSCollectionLayoutItem] = Array(repeating: trailingGroup, count: Int(numberOfGroups))
        subItems.insert(syncedTabItem, at: 0)
        let mainGroup = NSCollectionLayoutGroup.horizontal(layoutSize: mainGroupSize,
                                                           subitems: subItems)
        mainGroup.interItemSpacing = JumpBackInViewModel.UX.nestedGroupInterItemSpacing

        return NSCollectionLayoutSection(group: mainGroup)
    }

    var hasData: Bool {
        return !recentTabs.isEmpty || !(recentGroups?.isEmpty ?? true) || hasSyncedTab
    }

    func updateData(completion: @escaping () -> Void) {
        // Has to be on main due to tab manager needing main tread
        // This can be fixed when tab manager has been revisited
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completion()
                return
            }

            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            self.updateJumpBackInData {
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            self.updateRemoteTabs {
                dispatchGroup.leave()
            }

            dispatchGroup.notify(queue: .main) {
                completion()
            }
        }
    }

    func refreshData(for traitCollection: UITraitCollection) {
        jumpBackInList = createJumpBackInList(
            from: recentTabs,
            withMaxItemsToDisplay: maxItemsToDisplay(for: traitCollection, displayGroup: .jumpBackIn),
            and: recentGroups)
    }

    func updatePrivacyConcernedSection(isPrivate: Bool) {
        self.isPrivate = isPrivate
    }
}

// MARK: FxHomeSectionHandler
extension JumpBackInViewModel: HomepageSectionHandler {

    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        if isSyncedTabCell(for: indexPath, traitCollection: collectionView.traitCollection) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SyncedTabCell.cellIdentifier, for: indexPath)
            guard let syncedTabCell = cell as? SyncedTabCell else { return UICollectionViewCell() }

            let faviconImage = UIImage(imageLiteralResourceName: ImageIdentifiers.stackedTabsIcon).withRenderingMode(.alwaysTemplate)
            let cellViewModel = FxHomeSyncedTabCellViewModel(titleText: "Synced Tab",
                                                              descriptionText: "This is a synced tab",
                                                              tag: indexPath.item,
                                                              hasFavicon: true,
                                                              favIconImage: faviconImage)

            syncedTabCell.configure(viewModel: cellViewModel)
            return syncedTabCell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeHorizontalCell.cellIdentifier, for: indexPath)
            guard let jumpBackInCell = cell as? HomeHorizontalCell else { return UICollectionViewCell() }

            let jumpBackInItemRow = indexOfJumpBackInItem(for: indexPath, traitCollection: collectionView.traitCollection)
            if jumpBackInItemRow == (jumpBackInList.itemsToDisplay - 1),
               let group = jumpBackInList.group {
                configureJumpBackInCellForGroups(group: group, cell: jumpBackInCell, indexPath: indexPath)
            } else if let item = jumpBackInList.tabs[safe: jumpBackInItemRow] {
                configureJumpBackInCellForTab(item: item, cell: jumpBackInCell, indexPath: indexPath)
            } else {
                // TODO: Fix in the meantime we implement FXIOS-4310 && FXIOS-4095 for the reloading of the homepage.
                // We're in a state we shouldn't be in (an indexPath that gets configured when there's no tabs for it)
                // so for now we invalidate to avoid a crash. This happens only in a particular edge case,
                // but this code needs to be removed asap with proper homepage section reload.
                collectionView.collectionViewLayout.invalidateLayout()
            }
            return jumpBackInCell
        }
    }

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        // Setup is done through configure(collectionView:indexPath:), shouldn't be called
        return UICollectionViewCell()
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {

        if indexPath.row == jumpBackInList.itemsToDisplay - 1,
           let group = jumpBackInList.group {
            switchTo(group: group)

        } else {
            let tab = jumpBackInList.tabs[indexPath.row]
            switchTo(tab: tab)
        }
    }
}
