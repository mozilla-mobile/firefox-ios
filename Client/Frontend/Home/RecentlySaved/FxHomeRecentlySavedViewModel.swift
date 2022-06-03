// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage

class FxHomeRecentlySavedViewModel {

    struct UX {
        static let bookmarkItemsLimit: UInt = 5
        static let readingListItemsLimit: Int = 5
        static let cellWidth: CGFloat = 150
        static let cellHeight: CGFloat = 110
        static let generalSpacing: CGFloat = 8
        static let iPadGeneralSpacing: CGFloat = 8
    }

    // MARK: - Properties

    var isZeroSearch: Bool
    private let profile: Profile

    private lazy var siteImageHelper = SiteImageHelper(profile: profile)
    private var readingListItems = [ReadingListItem]()
    private var recentBookmarks = [BookmarkItemData]()
    private let recentItemsHelper = RecentItemsHelper()
    private let dataQueue = DispatchQueue(label: "com.moz.recentlySaved.queue")

    var headerButtonAction: ((UIButton) -> Void)?

    init(isZeroSearch: Bool, profile: Profile) {
        self.isZeroSearch = isZeroSearch
        self.profile = profile
    }

    var recentItems: [RecentlySavedItem] {
        var items = [RecentlySavedItem]()
        items.append(contentsOf: recentBookmarks)
        items.append(contentsOf: readingListItems)

        return items
    }

    func getHeroImage(forSite site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
            completion(image)
        }
    }

    // MARK: - Reading list

    private func getReadingLists(group: DispatchGroup) {
        group.enter()
        let maxItems = UX.readingListItemsLimit
        profile.readingList.getAvailableRecords().uponQueue(dataQueue, block: { [weak self] result in
            let items = result.successValue?.prefix(maxItems) ?? []
            self?.updateReadingList(readingList: Array(items))
            group.leave()
        })
    }

    private func updateReadingList(readingList: [ReadingListItem]) {
        readingListItems = recentItemsHelper.filterStaleItems(recentItems: readingList) as? [ReadingListItem] ?? []

        let extra = [TelemetryWrapper.EventObject.recentlySavedReadingItemImpressions.rawValue: "\(readingListItems.count)"]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .recentlySavedReadingListView,
                                     extras: extra)
    }

    // MARK: - Bookmarks

    private func getRecentBookmarks(group: DispatchGroup) {
        group.enter()
        profile.places.getRecentBookmarks(limit: UX.bookmarkItemsLimit).uponQueue(dataQueue, block: { [weak self] result in
            self?.updateRecentBookmarks(bookmarks: result.successValue ?? [])
            group.leave()
        })
    }

    private func updateRecentBookmarks(bookmarks: [BookmarkItemData]) {
        recentBookmarks = recentItemsHelper.filterStaleItems(recentItems: bookmarks) as? [BookmarkItemData] ?? []

        // Send telemetry if bookmarks aren't empty
        if !recentBookmarks.isEmpty {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedBookmarkItemView,
                                         extras: [TelemetryWrapper.EventObject.recentlySavedBookmarkImpressions.rawValue: "\(bookmarks.count)"])
        }
    }
}

// MARK: FXHomeViewModelProtocol
extension FxHomeRecentlySavedViewModel: FXHomeViewModelProtocol, FeatureFlaggable {

    var sectionType: FirefoxHomeSectionType {
        return .recentlySaved
    }

    var headerViewModel: ASHeaderViewModel {
        return ASHeaderViewModel(title: FirefoxHomeSectionType.recentlySaved.title,
                                 titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.recentlySaved,
                                 isButtonHidden: false,
                                 buttonTitle: .RecentlySavedShowAllText,
                                 buttonAction: headerButtonAction,
                                 buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.recentlySaved)
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(UX.cellWidth),
            heightDimension: .estimated(UX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(UX.cellWidth),
            heightDimension: .estimated(UX.cellHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                heightDimension: .estimated(34))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]

        let leadingInset = FirefoxHomeViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: leadingInset,
                                                        bottom: FirefoxHomeViewModel.UX.spacingBetweenSections, trailing: 0)

        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        section.interGroupSpacing = isIPad ? UX.iPadGeneralSpacing: UX.generalSpacing
        section.orthogonalScrollingBehavior = .continuous

        return section
    }

    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int {
        return recentItems.count
    }

    var isEnabled: Bool {
        return featureFlags.isFeatureEnabled(.recentlySaved, checking: .buildAndUser)
    }

    var hasData: Bool {
        return !recentBookmarks.isEmpty || !readingListItems.isEmpty
    }

    /// Using dispatch group to know when data has completely loaded for both sources (recent bookmarks and reading list items)
    func updateData(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        getRecentBookmarks(group: group)
        getReadingLists(group: group)

        group.notify(queue: .main) {
            completion()
        }
    }
}

// MARK: FxHomeSectionHandler
extension FxHomeRecentlySavedViewModel: FxHomeSectionHandler {

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {

        guard let recentlySavedCell = cell as? FxHomeRecentlySavedCell else { return UICollectionViewCell() }
        recentlySavedCell.tag = indexPath.row

        if let item = recentItems[safe: indexPath.row] {
            let site = Site(url: item.url, title: item.title, bookmarked: true)
            recentlySavedCell.itemTitle.text = site.title
            getHeroImage(forSite: site) { image in
                guard cell.tag == indexPath.row else { return }
                recentlySavedCell.heroImage.image = image
            }
        }

        return recentlySavedCell
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {

        if let item = recentItems[safe: indexPath.row] as? BookmarkItemData {
            guard let url = URIFixup.getURL(item.url) else { return }

            homePanelDelegate?.homePanel(didSelectURL: url, visitType: .bookmark, isGoogleTopSite: false)
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedBookmarkItemAction,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))

        } else if let item = recentItems[safe: indexPath.row] as? ReadingListItem,
                  let url = URL(string: item.url),
                  let encodedUrl = url.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) {

            let visitType = VisitType.bookmark
            libraryPanelDelegate?.libraryPanel(didSelectURL: encodedUrl, visitType: visitType)
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedReadingListAction,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))
        }
    }
}
