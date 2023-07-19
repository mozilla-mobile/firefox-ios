// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared

struct RecentlySavedCellViewModel {
    let site: Site
    var accessibilityLabel: String {
        return "\(site.title)"
    }
}

class RecentlySavedViewModel {
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
    private var recentlySavedDataAdaptor: RecentlySavedDataAdaptor
    private var recentItems = [RecentlySavedItem]()
    private var wallpaperManager: WallpaperManager
    var headerButtonAction: ((UIButton) -> Void)?

    weak var delegate: HomepageDataModelDelegate?

    init(profile: Profile,
         isZeroSearch: Bool = false,
         theme: Theme,
         wallpaperManager: WallpaperManager) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        self.theme = theme
        let adaptor = RecentlySavedDataAdaptorImplementation(readingList: profile.readingList,
                                                             bookmarksHandler: profile.places)
        self.recentlySavedDataAdaptor = adaptor
        self.wallpaperManager = wallpaperManager

        adaptor.delegate = self
    }
}

// MARK: HomeViewModelProtocol
extension RecentlySavedViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .recentlySaved
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        var textColor: UIColor?
        if wallpaperManager.featureAvailable {
            textColor = wallpaperManager.currentWallpaper.textColor
        }

        return LabelButtonHeaderViewModel(
            title: HomepageSectionType.recentlySaved.title,
            titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.recentlySaved,
            isButtonHidden: false,
            buttonTitle: .RecentlySavedShowAllText,
            buttonAction: headerButtonAction,
            buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.recentlySaved,
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
        return recentItems.count
    }

    var isEnabled: Bool {
        return featureFlags.isFeatureEnabled(.recentlySaved, checking: .buildAndUser)
    }

    var hasData: Bool {
        return !recentItems.isEmpty
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

// MARK: FxHomeSectionHandler
extension RecentlySavedViewModel: HomepageSectionHandler {
    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        guard let recentlySavedCell = cell as? RecentlySavedCell else { return UICollectionViewCell() }

        if let item = recentItems[safe: indexPath.row] {
            let site = Site(url: item.url, title: item.title, bookmarked: true)
            let viewModel = RecentlySavedCellViewModel(site: site)
            recentlySavedCell.configure(viewModel: viewModel, theme: theme)
        }

        return recentlySavedCell
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {
        if let item = recentItems[safe: indexPath.row] as? RecentlySavedBookmark {
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

extension RecentlySavedViewModel: RecentlySavedDelegate {
    func didLoadNewData() {
        ensureMainThread {
            self.recentItems = self.recentlySavedDataAdaptor.getRecentlySavedData()
            guard self.isEnabled else { return }
            self.delegate?.reloadView()
        }
    }
}
