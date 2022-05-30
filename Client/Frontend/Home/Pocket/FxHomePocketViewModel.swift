// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

class FxHomePocketViewModel {

    struct UX {
        static let numberOfItemsInColumn = 3
        static let discoverMoreMaxFontSize: CGFloat = 26 // Title 3 xxxLarge
        static let numberOfItemsInSection = 11
        static let fractionalWidthiPhonePortrait: CGFloat = 29/30
        static let fractionalWidthiPhoneLanscape: CGFloat = 7/15
    }

    // MARK: - Properties

    private let profile: Profile
    private let pocketAPI = Pocket()

    private let isZeroSearch: Bool
    private var hasSentPocketSectionEvent = false

    var onTapTileAction: ((URL) -> Void)?
    var onLongPressTileAction: ((Site, UIView?) -> Void)?

    init(profile: Profile, isZeroSearch: Bool) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
    }

    var pocketStories: [PocketStory] = []

    // The dimension of a cell
    // Fractions for iPhone to only show a slight portion of the next column
    static var widthDimension: NSCollectionLayoutDimension {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .absolute(FxHomeHorizontalCellUX.cellWidth) // iPad
        } else if UIWindow.isLandscape {
            return .fractionalWidth(UX.fractionalWidthiPhoneLanscape)
        } else {
            return .fractionalWidth(UX.fractionalWidthiPhonePortrait)
        }
    }

    var numberOfCells: Int {
        return pocketStories.count != 0 ? pocketStories.count + 1 : 0
    }

    static var numberOfItemsInColumn: CGFloat {
        return 3
    }

    func isStoryCell(index: Int) -> Bool {
        return index < pocketStories.count
    }

    func getSitesDetail(for index: Int) -> Site {
        if isStoryCell(index: index) {
            return Site(url: pocketStories[index].url.absoluteString, title: pocketStories[index].title)
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

    func domainAndReadingTimeForStory(atIndex: Int) -> String {
        let pocketStory = pocketStories[atIndex]
        let domainAndReadingTime = "\(pocketStory.domain) • \(String.localizedStringWithFormat(String.FirefoxHomepage.Pocket.NumberOfMinutes, pocketStory.timeToRead))"

        return domainAndReadingTime
    }

    // MARK: - Private

    private func getPocketSites() -> Success {
        return pocketAPI.globalFeed(items: UX.numberOfItemsInSection).bindQueue(.main) { pocketStory in
            self.pocketStories = pocketStory
            return succeed()
        }
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
            heightDimension: .estimated(FxHomeHorizontalCellUX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: FxHomePocketViewModel.widthDimension,
            heightDimension: .estimated(FxHomeHorizontalCellUX.cellHeight)
        )

        let subItems = Array(repeating: item, count: UX.numberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = FxHomeHorizontalCellUX.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0,
                                                      bottom: 0, trailing: FxHomeHorizontalCellUX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

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
        return !pocketStories.isEmpty
    }

    func updateData(completion: @escaping () -> Void) {
        getPocketSites().uponQueue(.main) { _ in
            completion()
        }
    }
}

// MARK: FxHomeSectionHandler
extension FxHomePocketViewModel: FxHomeSectionHandler {

    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell {

        recordSectionHasShown()

        if isStoryCell(index: indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FxHomeHorizontalCell.cellIdentifier, for: indexPath) as! FxHomeHorizontalCell
            let pocketStory = pocketStories[indexPath.row]
            let cellViewModel = FxHomeHorizontalCellViewModel(titleText: pocketStory.title,
                                                              descriptionText: domainAndReadingTimeForStory(atIndex: indexPath.row),
                                                              tag: indexPath.item,
                                                              hasFavicon: false)

            cell.configure(viewModel: cellViewModel)
            cell.setFallBackFaviconVisibility(isHidden: true)
            cell.heroImage.sd_setImage(with: pocketStory.imageURL)
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

        guard let showSiteWithURLHandler = onTapTileAction else { return }

        if isStoryCell(index: indexPath.row) {
            recordTapOnStory(index: indexPath.row)

            let siteUrl = pocketStories[indexPath.row].url
            showSiteWithURLHandler(siteUrl)

        } else {
            showSiteWithURLHandler(Pocket.MoreStoriesURL)
        }
    }
}
