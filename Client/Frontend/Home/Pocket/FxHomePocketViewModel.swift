// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

class FxHomePocketViewModel {

    struct UX {
        static let numberOfItemsInColumn = 3
        static let discoverMoreMaxFontSize: CGFloat = 55 // Title 3 xxxLarge
        static let numberOfItemsInSection = 11
        static let fractionalWidthiPhonePortrait: CGFloat = 0.93
        static let fractionalWidthiPhoneLanscape: CGFloat = 0.46
        static let numberOfSponsoredItemsInSection = 2
        static let indexOfFirstSponsoredItem = 1
        static let indexOfSecondSponsoredItem = 9
    }

    // MARK: - Properties

    private let pocketAPI = Pocket()

    private let isZeroSearch: Bool
    private var hasSentPocketSectionEvent = false

    var onTapTileAction: ((URL) -> Void)?
    var onLongPressTileAction: ((Site, UIView?) -> Void)?
    var onScroll: (() -> Void)?

    private(set) var pocketStoriesViewModels: [FxPocketHomeHorizontalCellViewModel] = []

    init(pocketStoriesViewModel: [FxPocketHomeHorizontalCellViewModel] = [], isZeroSearch: Bool) {
        self.isZeroSearch = isZeroSearch
        self.pocketStoriesViewModels = pocketStoriesViewModel
        for pocketStoryViewModel in pocketStoriesViewModel {
            bind(pocketStoryViewModel: pocketStoryViewModel)
        }
    }

    private func bind(pocketStoryViewModel: FxPocketHomeHorizontalCellViewModel) {
        pocketStoryViewModel.onTap = { [weak self] indexPath in
            self?.recordTapOnStory(index: indexPath.row)
            let siteUrl = self?.pocketStoriesViewModels[indexPath.row].url
            siteUrl.map { self?.onTapTileAction?($0) }
        }

        pocketStoriesViewModels.append(pocketStoryViewModel)
    }

    // The dimension of a cell
    // Fractions for iPhone to only show a slight portion of the next column
    static var widthDimension: NSCollectionLayoutDimension {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .absolute(FxPocketHomeHorizontalCell.UX.cellWidth) // iPad
        } else if UIWindow.isLandscape {
            return .fractionalWidth(UX.fractionalWidthiPhoneLanscape)
        } else {
            return .fractionalWidth(UX.fractionalWidthiPhonePortrait)
        }
    }

    var numberOfCells: Int {
        return pocketStoriesViewModels.count != 0 ? pocketStoriesViewModels.count + 1 : 0
    }

    static var numberOfItemsInColumn: CGFloat {
        return 3
    }

    func isStoryCell(index: Int) -> Bool {
        return index < pocketStoriesViewModels.count
    }

    func getSitesDetail(for index: Int) -> Site {
        if isStoryCell(index: index) {
            return Site(url: pocketStoriesViewModels[index].url?.absoluteString ?? "", title: pocketStoriesViewModels[index].title)
        } else {
            return Site(url: Pocket.MoreStoriesURL.absoluteString, title: .FirefoxHomepage.Pocket.DiscoverMore)
        }
    }

    // MARK: - Telemetry

    func recordSectionHasShown() {
        if !hasSentPocketSectionEvent {
            TelemetryWrapper.recordEvent(category: .action, method: .view, object: .pocketSectionImpression, value: nil, extras: nil)
            hasSentPocketSectionEvent = true
        }
    }

    func recordTapOnStory(index: Int) {
        // Pocket site extra
        let key = TelemetryWrapper.EventExtraKey.pocketTilePosition.rawValue
        let siteExtra = [key: "\(index)"]

        // Origin extra
        let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        let extras = originExtra.merge(with: siteExtra)

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pocketStory, value: nil, extras: extras)
    }

    // MARK: - Private

    func updatePocketStoryViewModels(with stories: [PocketStory]) {
        pocketStoriesViewModels = []
        for story in stories {
            bind(pocketStoryViewModel: .init(story: story))
        }
    }

    private func getPocketSites(completion: @escaping () -> Void) {
        pocketAPI
            .globalFeed(items: UX.numberOfItemsInSection)
            .uponQueue(.main) { [weak self] (pocketStory: [PocketFeedStory]) -> Void in
                var globalTemp = pocketStory.map(PocketStory.init)

                // Check if sponsored stories are enabled, otherwise drop api call
                guard self?.featureFlags.isFeatureEnabled(.sponsoredPocket, checking: .userOnly)  == true else {
                    self?.updatePocketStoryViewModels(with: globalTemp)
                    completion()
                    return
                }

                self?.pocketAPI.sponsoredFeed().uponQueue(.main) { sponsored in
                    // Convert sponsored feed to PocketStory, take the desired number of sponsored stories
                    var sponsoredTemp = sponsored.map(PocketStory.init).prefix(UX.numberOfSponsoredItemsInSection)

                    // Making sure we insert a sponsored story at a valid index
                    let firstIndex = min(UX.indexOfFirstSponsoredItem, globalTemp.endIndex)
                    sponsoredTemp.first.map { globalTemp.insert($0, at: firstIndex) }
                    sponsoredTemp.removeFirst()

                    let secondIndex = min(UX.indexOfSecondSponsoredItem, globalTemp.endIndex)
                    sponsoredTemp.first.map { globalTemp.insert($0, at: secondIndex) }
                    sponsoredTemp.removeFirst()

                    self?.updatePocketStoryViewModels(with: globalTemp)
                    completion()
                }
            }
    }

    func showDiscoverMore() {
        onTapTileAction?(Pocket.MoreStoriesURL)
    }
}

// MARK: FXHomeViewModelProtocol
extension FxHomePocketViewModel: FXHomeViewModelProtocol, FeatureFlaggable {

    var sectionType: FirefoxHomeSectionType {
        return .pocket
    }

    var headerViewModel: ASHeaderViewModel {
        return ASHeaderViewModel(title: FirefoxHomeSectionType.pocket.title,
                                 titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.pocket,
                                 isButtonHidden: true)
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(FxPocketHomeHorizontalCell.UX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: FxHomePocketViewModel.widthDimension,
            heightDimension: .estimated(FxPocketHomeHorizontalCell.UX.cellHeight)
        )

        let subItems = Array(repeating: item, count: UX.numberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = FxPocketHomeHorizontalCell.UX.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0,
                                                      bottom: 0, trailing: FxPocketHomeHorizontalCell.UX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                heightDimension: .estimated(34))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]
        section.visibleItemsInvalidationHandler = { (visibleItems, point, env) -> Void in
            self.onScroll?()
        }

        let leadingInset = FirefoxHomeViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: leadingInset,
                                                        bottom: FirefoxHomeViewModel.UX.spacingBetweenSections, trailing: 0)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }

    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int {
        return numberOfCells
    }

    var isEnabled: Bool {
        // For Pocket, the user preference check returns a user preference if it exists in
        // UserDefaults, and, if it does not, it will return a default preference based on
        // a (nimbus pocket section enabled && Pocket.isLocaleSupported) check
        guard featureFlags.isFeatureEnabled(.pocket, checking: .buildAndUser) else { return false }

        return true
    }

    var hasData: Bool {
        return !pocketStoriesViewModels.isEmpty
    }

    func updateData(completion: @escaping () -> Void) {
        getPocketSites(completion: completion)
    }
}

// MARK: FxHomeSectionHandler
extension FxHomePocketViewModel: FxHomeSectionHandler {

    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell {

        recordSectionHasShown()

        if isStoryCell(index: indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FxPocketHomeHorizontalCell.cellIdentifier, for: indexPath) as! FxPocketHomeHorizontalCell
            cell.configure(viewModel: pocketStoriesViewModels[indexPath.row])
            cell.tag = indexPath.item
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FxHomePocketDiscoverMoreCell.cellIdentifier, for: indexPath) as! FxHomePocketDiscoverMoreCell
            cell.itemTitle.text = .FirefoxHomepage.Pocket.DiscoverMore
            return cell
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

        if isStoryCell(index: indexPath.row) {
            pocketStoriesViewModels[indexPath.row].onTap(indexPath)

        } else {
            showDiscoverMore()
        }
    }

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath) {
        guard let onLongPressTileAction = onLongPressTileAction else { return }

        let site = getSitesDetail(for: indexPath.row)
        let sourceView = collectionView.cellForItem(at: indexPath)
        onLongPressTileAction(site, sourceView)
    }
}
