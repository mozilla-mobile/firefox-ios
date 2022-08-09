// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import UIKit

class JumpBackInViewModel: FeatureFlaggable {

    struct UX {
        static let jumpBackInCellHeight: CGFloat = 112
        static let syncedTabCellPortraitCompactHeight: CGFloat = 182
        static let syncedTabCellHeight: CGFloat = 232
        static let maxDisplayedSyncedTabs: Int = 1
        static let maxJumpBackInItemsPerGroup: Int = 2
    }

    // MARK: - Properties
    var headerButtonAction: ((UIButton) -> Void)?
    var onTapGroup: ((Tab) -> Void)?
    var syncedTabsShowAllAction: ((UIButton) -> Void)?
    var openSyncedTabAction: ((URL) -> Void)?

    weak var browserBarViewDelegate: BrowserBarViewDelegate?
    weak var delegate: HomepageDataModelDelegate?

    var jumpBackInList = JumpBackInList(group: nil, tabs: [Tab]())
    var mostRecentSyncedTab: JumpBackInSyncedTab?

    private lazy var siteImageHelper = SiteImageHelper(profile: profile)
    private var jumpBackInDataAdaptor: JumpBackInDataAdaptor

    var isZeroSearch: Bool
    private let profile: Profile
    private var isPrivate: Bool
    private var hasSentJumpBackInTileEvent = false
    private var hasSentSyncedTabTileEvent = false
    private let tabManager: TabManagerProtocol
    var sectionLayout: JumpBackInSectionLayout = .compactJumpBackIn // We use the compact layout as default

    init(
        isZeroSearch: Bool = false,
        profile: Profile,
        isPrivate: Bool,
        tabManager: TabManagerProtocol,
        adaptor: JumpBackInDataAdaptor
    ) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.isPrivate = isPrivate
        self.tabManager = tabManager
        self.jumpBackInDataAdaptor = adaptor
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

    func sendImpressionTelemetry() {
        if !hasSentJumpBackInTileEvent, hasJumpBackIn {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .jumpBackInTileImpressions,
                                         value: nil,
                                         extras: nil)
            hasSentJumpBackInTileEvent = true
        }

        if !hasSentSyncedTabTileEvent, hasSyncedTab {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .syncedTabTileImpressions,
                                         value: nil,
                                         extras: nil)
            hasSentSyncedTabTileEvent = true
        }
    }

    func updateSectionLayout(for traitCollection: UITraitCollection,
                             isPortrait: Bool = UIWindow.isPortrait,
                             device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        let isPhoneInLandscape = device == .phone && !isPortrait

        if hasSyncedTab, traitCollection.horizontalSizeClass == .compact, !isPhoneInLandscape {
            if hasJumpBackIn {
                sectionLayout = .compactJumpBackInAndSyncedTab
            } else {
                sectionLayout = .compactSyncedTab
            }
        } else if traitCollection.horizontalSizeClass == .compact, !isPhoneInLandscape {
            sectionLayout = .compactJumpBackIn
        } else {
            sectionLayout = hasSyncedTab ? .regularWithSyncedTab : .regular
        }
    }

    private var hasSyncedTab: Bool {
        return jumpBackInDataAdaptor.hasSyncedTabFeatureEnabled && mostRecentSyncedTab != nil
    }

    private var hasJumpBackIn: Bool {
        return jumpBackInList.itemsToDisplay > 0
    }
}

// MARK: - Private: Configure UI
private extension JumpBackInViewModel {

    func configureJumpBackInCellForGroups(group: ASGroup<Tab>, cell: JumpBackInCell, indexPath: IndexPath) {
        let firstGroupItem = group.groupedItems.first
        let site = Site(url: firstGroupItem?.lastKnownUrl?.absoluteString ?? "", title: firstGroupItem?.lastTitle ?? "")

        let descriptionText = String.localizedStringWithFormat(.FirefoxHomepage.JumpBackIn.GroupSiteCount, group.groupedItems.count)
        let faviconImage = UIImage(imageLiteralResourceName: ImageIdentifiers.stackedTabsIcon).withRenderingMode(.alwaysTemplate)
        let cellViewModel = JumpBackInCellViewModel(titleText: group.searchTerm.localizedCapitalized,
                                                    descriptionText: descriptionText,
                                                    favIconImage: faviconImage,
                                                    heroImage: jumpBackInDataAdaptor.getHeroImage(forSite: site))
        cell.configure(viewModel: cellViewModel)
    }

    func configureJumpBackInCellForTab(item: Tab, cell: JumpBackInCell, indexPath: IndexPath) {
        let itemURL = item.lastKnownUrl?.absoluteString ?? ""
        let site = Site(url: itemURL, title: item.displayTitle)
        let descriptionText = site.tileURL.shortDisplayString.capitalized

        let cellViewModel = JumpBackInCellViewModel(titleText: site.title,
                                                    descriptionText: descriptionText,
                                                    favIconImage: jumpBackInDataAdaptor.getFaviconImage(forSite: site),
                                                    heroImage: jumpBackInDataAdaptor.getHeroImage(forSite: site))
        cell.configure(viewModel: cellViewModel)
    }

    func configureSyncedTabCellForTab(item: JumpBackInSyncedTab, cell: SyncedTabCell, indexPath: IndexPath) {
        let itemURL = item.tab.URL.absoluteString
        let site = Site(url: itemURL, title: item.tab.title)
        let descriptionText = item.client.name
        let image = UIImage(named: ImageIdentifiers.syncedDevicesIcon)

        let cellViewModel = SyncedTabCellViewModel(titleText: site.title,
                                                         descriptionText: descriptionText,
                                                         url: item.tab.URL,
                                                         syncedDeviceImage: image,
                                                         heroImage: jumpBackInDataAdaptor.getHeroImage(forSite: site),
                                                         fallbackFaviconImage: jumpBackInDataAdaptor.getFaviconImage(forSite: site))
        cell.configure(viewModel: cellViewModel,
                       onTapShowAllAction: syncedTabsShowAllAction,
                       onOpenSyncedTabAction: openSyncedTabAction)
    }

    private func defaultSection(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let groupWidth = sectionLayout.widthDimension

        // Items
        let syncedTabItemSize = NSCollectionLayoutSize(
            widthDimension: groupWidth,
            heightDimension: .estimated(JumpBackInViewModel.UX.syncedTabCellHeight))
        let syncedTabItem = NSCollectionLayoutItem(layoutSize: syncedTabItemSize)

        let jumpBackInItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(JumpBackInViewModel.UX.jumpBackInCellHeight))
        let jumpBackInItem = NSCollectionLayoutItem(layoutSize: jumpBackInItemSize)

        // Nested Group (Jump Back In)
        let nestedGroupSize = NSCollectionLayoutSize(widthDimension: groupWidth,
                                                       heightDimension: .fractionalHeight(1))
        let nestedGroup = NSCollectionLayoutGroup.vertical(layoutSize: nestedGroupSize,
                                                             subitems: [jumpBackInItem, jumpBackInItem])
        nestedGroup.interItemSpacing = JumpBackInCell.UX.interItemSpacing

        // Main Group
        let mainGroupHeight: CGFloat = JumpBackInViewModel.UX.syncedTabCellHeight
        let mainGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(mainGroupHeight))

        let maxJumpBackInPerGroup = JumpBackInViewModel.UX.maxJumpBackInItemsPerGroup
        let jumpBackInItems = jumpBackInList.itemsToDisplay
        let numberOfGroups = ceil(Double(jumpBackInItems) / Double(maxJumpBackInPerGroup))
        var subItems: [NSCollectionLayoutItem] = Array(repeating: nestedGroup, count: Int(numberOfGroups))

        if hasSyncedTab {
            subItems.insert(syncedTabItem, at: 0)
        }
        let mainGroup = NSCollectionLayoutGroup.horizontal(layoutSize: mainGroupSize,
                                                           subitems: subItems)
        mainGroup.interItemSpacing = JumpBackInCell.UX.interItemSpacing

        return NSCollectionLayoutSection(group: mainGroup)
    }

    // compact layout with synced tab
    private func sectionWithSyncedTabCompact(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        // Items
        let syncedTabCellHeight = JumpBackInViewModel.UX.syncedTabCellPortraitCompactHeight
        let syncedTabItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(syncedTabCellHeight))
        let syncedTabItem = NSCollectionLayoutItem(layoutSize: syncedTabItemSize)

        let jumpBackInItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(JumpBackInViewModel.UX.jumpBackInCellHeight))
        let jumpBackInItem = NSCollectionLayoutItem(layoutSize: jumpBackInItemSize)

        // Main Group
        let groupWidth = sectionLayout.widthDimension
        let groupHeight: CGFloat = syncedTabCellHeight + JumpBackInViewModel.UX.jumpBackInCellHeight
        + JumpBackInCell.UX.interItemSpacing.spacing
        let groupSize = NSCollectionLayoutSize(widthDimension: groupWidth,
                                               heightDimension: .estimated(groupHeight))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize,
                                                     subitems: [jumpBackInItem, syncedTabItem])
        group.interItemSpacing = JumpBackInCell.UX.interItemSpacing

        return NSCollectionLayoutSection(group: group)
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

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        var section: NSCollectionLayoutSection
        updateSectionLayout(for: traitCollection,
                            isPortrait: UIWindow.isPortrait,
                            device: UIDevice.current.userInterfaceIdiom)

        switch sectionLayout {
        case .compactSyncedTab, .compactJumpBackInAndSyncedTab:
            section = sectionWithSyncedTabCompact(for: traitCollection)
        case .compactJumpBackIn, .regular, .regularWithSyncedTab:
            section = defaultSection(for: traitCollection)
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
        section.interGroupSpacing = JumpBackInCell.UX.interGroupSpacing

        return section
    }

    var hasData: Bool {
        return hasJumpBackIn || hasSyncedTab
    }

    func updateData(completion: @escaping () -> Void) {
        jumpBackInList = jumpBackInDataAdaptor.getJumpBackInData()
        mostRecentSyncedTab = jumpBackInDataAdaptor.getSyncedTabData()
        completion()
    }

    func refreshData(for traitCollection: UITraitCollection,
                     device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        let maxItemToDisplay = sectionLayout.maxItemsToDisplay(
            displayGroup: .jumpBackIn,
            hasAccount: jumpBackInDataAdaptor.hasSyncedTabFeatureEnabled,
            device: device
        )
        jumpBackInDataAdaptor.refreshData(maxItemToDisplay: maxItemToDisplay)

        jumpBackInList = jumpBackInDataAdaptor.getJumpBackInData()
        mostRecentSyncedTab = jumpBackInDataAdaptor.getSyncedTabData()
    }

    func updatePrivacyConcernedSection(isPrivate: Bool) {
        self.isPrivate = isPrivate
    }
}

// MARK: FxHomeSectionHandler
extension JumpBackInViewModel: HomepageSectionHandler {

    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        if let jumpBackInItemRow = sectionLayout.indexOfJumpBackInItem(for: indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JumpBackInCell.cellIdentifier,
                                                          for: indexPath)
            guard let jumpBackInCell = cell as? JumpBackInCell else { return UICollectionViewCell() }

            if jumpBackInItemRow == (jumpBackInList.itemsToDisplay - 1),
               let group = jumpBackInList.group {
                configureJumpBackInCellForGroups(group: group, cell: jumpBackInCell, indexPath: indexPath)
            } else if let item = jumpBackInList.tabs[safe: jumpBackInItemRow] {
                configureJumpBackInCellForTab(item: item, cell: jumpBackInCell, indexPath: indexPath)
            }
            return jumpBackInCell

        } else if hasSyncedTab {
            // SyncedTab cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SyncedTabCell.cellIdentifier,
                                                          for: indexPath)
            guard let syncedTabCell = cell as? SyncedTabCell,
                    let mostRecentSyncedTab = mostRecentSyncedTab
            else { return UICollectionViewCell() }
            configureSyncedTabCellForTab(item: mostRecentSyncedTab, cell: syncedTabCell, indexPath: indexPath)
            return syncedTabCell
        }

        // something went wrong
        return UICollectionViewCell()
    }

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        // Setup is done through configure(collectionView:indexPath:), shouldn't be called
        return UICollectionViewCell()
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {
        if let jumpBackInItemRow = sectionLayout.indexOfJumpBackInItem(for: indexPath) {
            // JumpBackIn cell
            if jumpBackInItemRow == jumpBackInList.itemsToDisplay - 1,
               let group = jumpBackInList.group {
                switchTo(group: group)

            } else if let tab = jumpBackInList.tabs[safe: jumpBackInItemRow] {
                switchTo(tab: tab)
            }
        } else if hasSyncedTab {
            // SyncedTab cell
            // do nothing, will be handled in cell depending on area tapped
        }
    }
}

extension JumpBackInViewModel: JumpBackInDelegate {
    func didLoadNewData() {
        ensureMainThread {
            self.jumpBackInList = self.jumpBackInDataAdaptor.getJumpBackInData()
            self.mostRecentSyncedTab = self.jumpBackInDataAdaptor.getSyncedTabData()
            self.delegate?.reloadView()
        }
    }
}
