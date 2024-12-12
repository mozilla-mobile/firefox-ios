// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import UIKit
import Shared

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
    var syncedTabsShowAllAction: (() -> Void)?
    var openSyncedTabAction: ((URL) -> Void)?
    var onLongPressTileAction: ((Site, UIView?) -> Void)?
    var prepareContextualHint: ((SyncedTabCell) -> Void)?

    weak var delegate: HomepageDataModelDelegate?

    // The data that is showed to the user after layout calculation
    var jumpBackInList = JumpBackInList(tabs: [Tab]())
    var mostRecentSyncedTab: JumpBackInSyncedTab?

    // Raw data to calculate what we can show to the user
    var recentTabs = [Tab]()
    var recentSyncedTab: JumpBackInSyncedTab?

    private var jumpBackInDataAdaptor: JumpBackInDataAdaptor

    var isZeroSearch: Bool
    var theme: Theme
    private let profile: Profile
    private var isPrivate: Bool
    private var hasSentJumpBackInTileEvent = false
    private var hasSentSyncedTabTileEvent = false
    private let tabManager: TabManager
    private var wallpaperManager: WallpaperManager
    private var logger: Logger
    var sectionLayout: JumpBackInSectionLayout = .compactJumpBackIn // We use the compact layout as default

    init(
        isZeroSearch: Bool = false,
        profile: Profile,
        isPrivate: Bool,
        theme: Theme,
        tabManager: TabManager,
        adaptor: JumpBackInDataAdaptor,
        wallpaperManager: WallpaperManager,
        logger: Logger = DefaultLogger.shared
    ) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.isPrivate = isPrivate
        self.theme = theme
        self.tabManager = tabManager
        self.jumpBackInDataAdaptor = adaptor
        self.wallpaperManager = wallpaperManager
        self.logger = logger
    }

    func switchTo(tab: Tab) {
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

    private func updateSectionLayout(for traitCollection: UITraitCollection,
                                     isPortrait: Bool,
                                     device: UIUserInterfaceIdiom,
                                     orientation: UIDeviceOrientation) {
        let isPhoneInLandscape = device == .phone && !isPortrait
        let isPadInPortrait = device == .pad && isPortrait
        let isPadInLandscapeTwoThirdSplit = isPadInLandscapeSplit(split: 2/3, isPortrait: isPortrait, device: device)
        let isPadInLandscapeHalfSplit = isPadInLandscapeSplit(split: 1/2, isPortrait: isPortrait, device: device)

        if hasSyncedTab, traitCollection.horizontalSizeClass == .compact, !isPhoneInLandscape {
            if hasJumpBackIn {
                sectionLayout = .compactJumpBackInAndSyncedTab
            } else {
                sectionLayout = .compactSyncedTab
            }
        } else if traitCollection.horizontalSizeClass == .compact, !isPhoneInLandscape {
            sectionLayout = .compactJumpBackIn
        } else if isPadInPortrait || isPhoneInLandscape || isPadInLandscapeHalfSplit || isPadInLandscapeTwoThirdSplit {
            sectionLayout = hasSyncedTab ? .mediumWithSyncedTab : .medium
        } else {
            sectionLayout = hasSyncedTab ? .regularWithSyncedTab : .regular
        }
    }

    private var isSyncTabFeatureEnabled = false

    private var hasSyncedTab: Bool {
        return isSyncTabFeatureEnabled && recentSyncedTab != nil
    }

    private var hasJumpBackIn: Bool {
        return !recentTabs.isEmpty
    }

    private var isMultitasking: Bool {
        guard let window = UIWindow.keyWindow else { return false }

        return window.frame.width != window.screen.bounds.width && window.frame.width != window.screen.bounds.height
    }

    private func isPadInLandscapeSplit(split: CGFloat,
                                       isPortrait: Bool,
                                       device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) -> Bool {
        guard device == .pad,
              !isPortrait,
              isMultitasking,
              let window = UIWindow.keyWindow
        else { return false }

        let splitScreenWidth = window.screen.bounds.width * split
        return window.frame.width >= splitScreenWidth * 0.9 && window.frame.width <= splitScreenWidth * 1.1
    }
}

// MARK: - Private: Prepare UI data
private extension JumpBackInViewModel {
    private func refreshData(maxItemsToDisplay: JumpBackInDisplayGroupCount) {
        jumpBackInList = createJumpBackInList(
            from: recentTabs,
            withMaxTabsCount: maxItemsToDisplay.tabsCount
        )
        let shouldShowSyncTab = maxItemsToDisplay.syncedTabCount >= 1 && hasSyncedTab
        mostRecentSyncedTab = shouldShowSyncTab ? recentSyncedTab : nil
    }

    func createJumpBackInList(
        from tabs: [Tab],
        withMaxTabsCount maxTabs: Int
    ) -> JumpBackInList {
        let recentTabs = filter(
            tabs: tabs,
            withMaxTabsCount: maxTabs)

        return JumpBackInList(tabs: recentTabs)
    }

    func filter(
        tabs: [Tab],
        withMaxTabsCount maxTabs: Int
    ) -> [Tab] {
        guard tabs.count > maxTabs else { return tabs }
        let dropCount = tabs.count - maxTabs
        return tabs.dropLast(dropCount)
    }
}

// MARK: - Private: Configure UI
private extension JumpBackInViewModel {
    func configureJumpBackInCellForTab(item: Tab, cell: JumpBackInCell, indexPath: IndexPath) {
        let itemURL = item.lastKnownUrl?.absoluteString ?? ""
        let site = Site(url: itemURL, title: item.displayTitle)
        let descriptionText = site.tileURL.shortDisplayString.capitalized
        let cellViewModel = JumpBackInCellViewModel(titleText: site.title,
                                                    descriptionText: descriptionText,
                                                    siteURL: itemURL)
        cell.configure(viewModel: cellViewModel, theme: theme)
    }

    func configureSyncedTabCellForTab(item: JumpBackInSyncedTab, cell: SyncedTabCell, indexPath: IndexPath) {
        let itemURL = item.tab.URL.absoluteString
        let site = Site(url: itemURL, title: item.tab.title)
        let descriptionText = item.client.name
        let image = UIImage(named: StandardImageIdentifiers.Large.syncTabs)

        let cellViewModel = SyncedTabCellViewModel(
            profile: profile,
            titleText: site.title,
            descriptionText: descriptionText,
            url: item.tab.URL,
            syncedDeviceImage: image
        )

        cell.configure(
            viewModel: cellViewModel,
            theme: theme,
            onTapShowAllAction: syncedTabsShowAllAction,
            onOpenSyncedTabAction: openSyncedTabAction
        )
    }

    private func defaultSection(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let groupWidth = sectionLayout.widthDimension

        // Items
        let syncedTabItemSize = NSCollectionLayoutSize(
            widthDimension: groupWidth,
            heightDimension: .estimated(UX.syncedTabCellHeight))
        let syncedTabItem = NSCollectionLayoutItem(layoutSize: syncedTabItemSize)

        let jumpBackInItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.jumpBackInCellHeight))
        let jumpBackInItem = NSCollectionLayoutItem(layoutSize: jumpBackInItemSize)

        // Nested Group (Jump Back In)
        let nestedGroupSize = NSCollectionLayoutSize(widthDimension: groupWidth,
                                                     heightDimension: .estimated(UX.syncedTabCellHeight))
        let nestedGroup = NSCollectionLayoutGroup.vertical(layoutSize: nestedGroupSize,
                                                           subitems: [jumpBackInItem, jumpBackInItem])
        nestedGroup.interItemSpacing = JumpBackInCell.UX.interItemSpacing

        // Main Group
        let mainGroupHeight: CGFloat = UX.syncedTabCellHeight
        let mainGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(mainGroupHeight))

        let maxJumpBackInPerGroup = UX.maxJumpBackInItemsPerGroup
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
        let syncedTabCellHeight = UX.syncedTabCellPortraitCompactHeight
        let syncedTabItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(syncedTabCellHeight))
        let syncedTabItem = NSCollectionLayoutItem(layoutSize: syncedTabItemSize)

        let jumpBackInItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.jumpBackInCellHeight))
        let jumpBackInItem = NSCollectionLayoutItem(layoutSize: jumpBackInItemSize)

        // Main Group
        let groupWidth = sectionLayout.widthDimension
        let groupHeight: CGFloat = syncedTabCellHeight + UX.jumpBackInCellHeight
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
        let textColor = wallpaperManager.currentWallpaper.textColor

        return LabelButtonHeaderViewModel(
            title: HomepageSectionType.jumpBackIn.title,
            titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.jumpBackIn,
            isButtonHidden: false,
            buttonTitle: .BookmarksSavedShowAllText,
            buttonAction: headerButtonAction,
            buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn,
            textColor: textColor)
    }

    var isEnabled: Bool {
        guard featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildAndUser) else { return false }

        return !isPrivate
    }

    func numberOfItemsInSection() -> Int {
        return jumpBackInList.itemsToDisplay + (hasSyncedTab ? UX.maxDisplayedSyncedTabs : 0)
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        var section: NSCollectionLayoutSection
        switch sectionLayout {
        case .compactSyncedTab, .compactJumpBackInAndSyncedTab:
            section = sectionWithSyncedTabCompact(for: traitCollection)
        case .compactJumpBackIn, .regular, .regularWithSyncedTab, .medium, .mediumWithSyncedTab:
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
                                                        trailing: 0)
        section.interGroupSpacing = JumpBackInCell.UX.interGroupSpacing

        return section
    }

    var hasData: Bool {
        return hasJumpBackIn || hasSyncedTab
    }

    func refreshData(for traitCollection: UITraitCollection,
                     size: CGSize,
                     isPortrait: Bool = UIWindow.isPortrait,
                     device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
                     orientation: UIDeviceOrientation = UIDevice.current.orientation) {
        // UIDevice is not always returning the correct orientation so we check against the window orientation as well
        let isPortrait = orientation.isPortrait || isPortrait
        updateSectionLayout(for: traitCollection,
                            isPortrait: isPortrait,
                            device: device,
                            orientation: orientation)
        let maxItemsToDisplay = sectionLayout.maxItemsToDisplay(
            hasAccount: isSyncTabFeatureEnabled,
            device: device
        )
        refreshData(maxItemsToDisplay: maxItemsToDisplay)
        logger.log("JumpBackIn section shouldShow \(shouldShow)",
                   level: .debug,
                   category: .legacyHomepage)
    }

    func updatePrivacyConcernedSection(isPrivate: Bool) {
        self.isPrivate = isPrivate
    }

    func screenWasShown() {
        hasSentJumpBackInTileEvent = false
    }

    func setTheme(theme: Theme) {
        self.theme = theme
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

            if let item = jumpBackInList.tabs[safe: jumpBackInItemRow] {
                configureJumpBackInCellForTab(item: item, cell: jumpBackInCell, indexPath: indexPath)
            }
            return jumpBackInCell
        } else if hasSyncedTab {
            // SyncedTab cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SyncedTabCell.cellIdentifier,
                                                          for: indexPath)
            guard let syncedTabCell = cell as? SyncedTabCell,
                  let mostRecentSyncedTab = mostRecentSyncedTab,
                  let prepareContextualHint = prepareContextualHint
            else { return UICollectionViewCell() }
            configureSyncedTabCellForTab(item: mostRecentSyncedTab, cell: syncedTabCell, indexPath: indexPath)
            prepareContextualHint(syncedTabCell)
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
            if let tab = jumpBackInList.tabs[safe: jumpBackInItemRow] {
                switchTo(tab: tab)
            }
        } else if hasSyncedTab {
            // SyncedTab cell
            // do nothing, will be handled in cell depending on area tapped
        }
    }

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath) {
        guard let tileLongPressedHandler = onLongPressTileAction else { return }

        var site = Site(url: "", title: "")
        if let jumpBackInItemRow = sectionLayout.indexOfJumpBackInItem(for: indexPath) {
            if let item = jumpBackInList.tabs[safe: jumpBackInItemRow] {
                site = Site(url: item.url?.absoluteString ?? "", title: item.title ?? "")
            }
        } else if hasSyncedTab {
            site = Site(
                url: mostRecentSyncedTab?.tab.URL.absoluteString ?? "",
                title: mostRecentSyncedTab?.tab.title ?? ""
            )
        }

        let sourceView = collectionView.cellForItem(at: indexPath)
        tileLongPressedHandler(site, sourceView)
    }
}

extension JumpBackInViewModel: JumpBackInDelegate {
    func didLoadNewData() {
        Task { @MainActor in
            await self.updateJumpBackInData()
            logger.log("JumpBack didLoadNewData and section shouldShow \(self.shouldShow)",
                       level: .debug,
                       category: .legacyHomepage)
            reloadView()
        }
    }

    private func updateJumpBackInData() async {
        self.recentTabs = await self.jumpBackInDataAdaptor.getRecentTabData()
        self.recentSyncedTab = await self.jumpBackInDataAdaptor.getSyncedTabData()
        self.isSyncTabFeatureEnabled = await self.jumpBackInDataAdaptor.hasSyncedTabFeatureEnabled()
    }

    private func reloadView() {
        guard self.isEnabled else { return }
        self.delegate?.reloadView()
    }
}
