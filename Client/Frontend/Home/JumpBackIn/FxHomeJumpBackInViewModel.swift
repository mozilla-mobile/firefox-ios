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

class FirefoxHomeJumpBackInViewModel: FeatureFlaggable {

    struct UX {
        static let verticalCellSpacing: CGFloat = 8
        static let iPadHorizontalSpacing: CGFloat = 48
        static let iPadCellSpacing: CGFloat = 16
        static let iPhoneLandscapeCellWidth: CGFloat = 0.475
        static let iPhonePortraitCellWidth: CGFloat = 0.95
    }

    // MARK: - Properties
    var onTapGroup: ((Tab) -> Void)?
    var jumpBackInList = JumpBackInList(group: nil, tabs: [Tab]())
    var headerButtonAction: ((UIButton) -> Void)?

    private var recentTabs: [Tab] = [Tab]()
    private var recentGroups: [ASGroup<Tab>]?
    private let isZeroSearch: Bool
    private let profile: Profile
    private let tabManager: TabManager
    private lazy var siteImageHelper = SiteImageHelper(profile: profile)
    private var isPrivate: Bool

    init(isZeroSearch: Bool = false,
         profile: Profile,
         isPrivate: Bool,
         tabManager: TabManager = BrowserViewController.foregroundBVC().tabManager
    ) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.isPrivate = isPrivate
        self.tabManager = tabManager
    }

    // The dimension of a cell
    static var widthDimension: NSCollectionLayoutDimension {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .absolute(FxHomeHorizontalCellUX.cellWidth) // iPad
        } else if UIWindow.isLandscape {
            return .fractionalWidth(UX.iPhoneLandscapeCellWidth) // iPhone in landscape
        } else {
            return .fractionalWidth(UX.iPhonePortraitCellWidth) // iPhone in portrait
        }
    }

    // The maximum number of items to display in the whole section
    static var maxItemsToDisplay: Int {
        return UIDevice.current.userInterfaceIdiom == .pad ? 3 : (UIWindow.isLandscape ? 4 : 2)
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

    /// Refresh data for new layout
    func refreshData() {
        jumpBackInList = createJumpBackInList(
            from: recentTabs,
            withMaxItemsToDisplay: FirefoxHomeJumpBackInViewModel.maxItemsToDisplay,
            and: recentGroups)
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

    private func createJumpBackInList(from tabs: [Tab],
                                      withMaxItemsToDisplay maxItems: Int,
                                      and groups: [ASGroup<Tab>]? = nil
    ) -> JumpBackInList {
        let recentGroup = groups?.first
        let groupCount = recentGroup != nil ? 1 : 0
        let recentTabs = filter(tabs: tabs,
                                from: recentGroup,
                                usingGroupCount: groupCount,
                                withMaxItemsToDisplay: maxItems)

        return JumpBackInList(group: recentGroup, tabs: recentTabs)
    }

    private func filter(
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

    /// Update data with tab and search term group managers
    private func updateJumpBackInData(completion: @escaping () -> Void) {
        recentTabs = tabManager.recentlyAccessedNormalTabs
        let maxItemsToDisplay = FirefoxHomeJumpBackInViewModel.maxItemsToDisplay

        if featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildAndUser) {
            SearchTermGroupsUtility.getTabGroups(with: profile,
                                                 from: recentTabs,
                                                 using: .orderedDescending) { [weak self] groups, _ in
                guard let strongSelf = self else { completion(); return }
                strongSelf.recentGroups = groups
                strongSelf.jumpBackInList = strongSelf.createJumpBackInList(
                    from: strongSelf.recentTabs,
                    withMaxItemsToDisplay: maxItemsToDisplay,
                    and: groups)
                completion()
            }

        } else {
            jumpBackInList = createJumpBackInList(from: recentTabs,
                                                  withMaxItemsToDisplay: maxItemsToDisplay)
            completion()
        }
    }
}

// MARK: FXHomeViewModelProtocol
extension FirefoxHomeJumpBackInViewModel: FXHomeViewModelProtocol {

    var sectionType: FirefoxHomeSectionType {
        return .jumpBackIn
    }

    var headerViewModel: ASHeaderViewModel {
        return ASHeaderViewModel(title: FirefoxHomeSectionType.jumpBackIn.title,
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
        return jumpBackInList.itemsToDisplay
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(FxHomeHorizontalCellUX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: FirefoxHomeJumpBackInViewModel.widthDimension,
            heightDimension: .estimated(FxHomeHorizontalCellUX.cellHeight)
        )

        let itemsNumber = numberOfItemsInSection(for: traitCollection)
        let count = min(FirefoxHomeJumpBackInViewModel.maxNumberOfItemsInColumn, itemsNumber)
        let subItems = Array(repeating: item, count: count)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = FxHomeHorizontalCellUX.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0,
                                                      bottom: 0, trailing: FxHomeHorizontalCellUX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuous
        return section
    }

    var hasData: Bool {
        return jumpBackInList.itemsToDisplay != 0
    }

    func updateData(completion: @escaping () -> Void) {
        // Has to be on main due to tab manager needing main tread
        // This can be fixed when tab manager has been revisited
        DispatchQueue.main.async {
            self.updateJumpBackInData(completion: completion)
        }
    }

    var shouldReloadSection: Bool { return true }

    func updatePrivacyConcernedSection(isPrivate: Bool) {
        self.isPrivate = isPrivate
    }
}

// MARK: FxHomeSectionHandler
extension FirefoxHomeJumpBackInViewModel: FxHomeSectionHandler {

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {

        guard let jumpBackInCell = cell as? FxHomeHorizontalCell else { return UICollectionViewCell() }

        if indexPath.row == (jumpBackInList.itemsToDisplay - 1),
           let group = jumpBackInList.group {
            configureCellForGroups(group: group, cell: jumpBackInCell, indexPath: indexPath)
        } else {
            configureCellForTab(item: jumpBackInList.tabs[indexPath.row], cell: jumpBackInCell, indexPath: indexPath)
        }

        return cell
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

    private func configureCellForGroups(group: ASGroup<Tab>, cell: FxHomeHorizontalCell, indexPath: IndexPath) {
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

    private func configureCellForTab(item: Tab, cell: FxHomeHorizontalCell, indexPath: IndexPath) {
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
