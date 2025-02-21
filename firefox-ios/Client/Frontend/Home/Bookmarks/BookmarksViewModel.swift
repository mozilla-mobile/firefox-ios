// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared

import enum MozillaAppServices.VisitType

struct BookmarksCellViewModel {
    let site: Site
    var accessibilityLabel: String {
        return "\(site.title)"
    }
}

class BookmarksViewModel {
    struct UX {
        static let cellWidth: CGFloat = 150
        static let cellHeight: CGFloat = 110
        static let generalSpacing: CGFloat = 8
        static let iPadGeneralSpacing: CGFloat = 8
    }

    // MARK: - Properties

    var isZeroSearch: Bool
    var theme: Theme
    private let profile: Profile
    private var bookmarkDataAdaptor: BookmarksDataAdaptor
    private var bookmarkItems = [BookmarkItem]()
    private var wallpaperManager: WallpaperManager
    var headerButtonAction: ((UIButton) -> Void)?
    var onLongPressTileAction: ((Site, UIView?) -> Void)?

    weak var delegate: HomepageDataModelDelegate?

    init(profile: Profile,
         isZeroSearch: Bool = false,
         theme: Theme,
         wallpaperManager: WallpaperManager) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.theme = theme
        let adaptor = BookmarksDataAdaptorImplementation(bookmarksHandler: profile.places)
        self.bookmarkDataAdaptor = adaptor
        self.wallpaperManager = wallpaperManager

        adaptor.delegate = self
    }
}

// MARK: HomeViewModelProtocol
extension BookmarksViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .bookmarks
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        let textColor = wallpaperManager.currentWallpaper.textColor

        return LabelButtonHeaderViewModel(
            title: HomepageSectionType.bookmarks.title,
            titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.bookmarks,
            isButtonHidden: false,
            buttonTitle: .BookmarksSavedShowAllText,
            buttonAction: headerButtonAction,
            buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.bookmarks,
            textColor: textColor)
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
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

        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: leadingInset,
            bottom: HomepageViewModel.UX.spacingBetweenSections,
            trailing: 0)

        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        section.interGroupSpacing = isIPad ? UX.iPadGeneralSpacing: UX.generalSpacing
        section.orthogonalScrollingBehavior = .continuous

        return section
    }

    func numberOfItemsInSection() -> Int {
        return bookmarkItems.count
    }

    var isEnabled: Bool {
        return profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.BookmarksSection) ?? true
    }

    var hasData: Bool {
        return !bookmarkItems.isEmpty
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

// MARK: FxHomeSectionHandler
extension BookmarksViewModel: HomepageSectionHandler {
    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        guard let bookmarksCell = cell as? LegacyBookmarksCell else { return UICollectionViewCell() }

        if let item = bookmarkItems[safe: indexPath.row] {
            let site = Site.createBasicSite(url: item.url, title: item.title, isBookmarked: true)
            let viewModel = BookmarksCellViewModel(site: site)
            bookmarksCell.configure(viewModel: viewModel, theme: theme)
        }

        return bookmarksCell
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {
        if let item = bookmarkItems[safe: indexPath.row] as? Bookmark {
            guard let url = URIFixup.getURL(item.url) else { return }

            homePanelDelegate?.homePanel(didSelectURL: url, visitType: .bookmark, isGoogleTopSite: false)
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .bookmarkItemAction,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))
        }
    }

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath) {
        guard let onLongPressTileAction = onLongPressTileAction else { return }

        let site = Site.createBasicSite(url: bookmarkItems[indexPath.row].url,
                                        title: bookmarkItems[indexPath.row].title)
        let sourceView = collectionView.cellForItem(at: indexPath)
        onLongPressTileAction(site, sourceView)
    }
}

extension BookmarksViewModel: BookmarksDelegate {
    func didLoadNewData() {
        ensureMainThread {
            self.bookmarkItems = self.bookmarkDataAdaptor.getBookmarkData()
            guard self.isEnabled else { return }
            self.delegate?.reloadView()
        }
    }
}
