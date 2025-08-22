// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared

// TODO: - FXIOS-12756 the class should conform to Sendable
class StoryViewModel: @unchecked Sendable {
    struct UX {
        static let numberOfItemsInColumn = 3
        static let fractionalWidthiPhonePortrait: CGFloat = 0.90
        static let fractionalWidthiPhoneLandscape: CGFloat = 0.46
        static let sectionBottomSpacing: CGFloat = 16
        static let headerFooterHeight: CGFloat = 34
    }

    // MARK: - Properties

    var isZeroSearch: Bool
    var theme: Theme
    private var hasSentPocketSectionEvent = false

    var onTapTileAction: ((URL) -> Void)?
    var onLongPressTileAction: ((Site, UIView?) -> Void)?
    weak var delegate: HomepageDataModelDelegate?

    private var dataAdaptor: StoryDataAdaptor
    private var storiesViewModels = [StoryStandardCellViewModel]()
    private var wallpaperManager: WallpaperManager
    private var prefs: Prefs
    private let logger: Logger

    init(pocketDataAdaptor: StoryDataAdaptor,
         isZeroSearch: Bool = false,
         theme: Theme,
         prefs: Prefs,
         wallpaperManager: WallpaperManager,
         logger: Logger = DefaultLogger.shared) {
        self.dataAdaptor = pocketDataAdaptor
        self.isZeroSearch = isZeroSearch
        self.theme = theme
        self.prefs = prefs
        self.wallpaperManager = wallpaperManager
        self.logger = logger
    }

    // The dimension of a cell
    // Fractions for iPhone to only show a slight portion of the next column
    func getWidthDimension(device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
                           isLandscape: Bool = UIWindow.isLandscape) -> NSCollectionLayoutDimension {
        if device == .pad {
            return .absolute(LegacyPocketStandardCell.UX.cellWidth) // iPad
        } else if isLandscape {
            return .fractionalWidth(UX.fractionalWidthiPhoneLandscape)
        } else {
            return .fractionalWidth(UX.fractionalWidthiPhonePortrait)
        }
    }

    private func getSitesDetail(for index: Int) -> Site {
        return Site.createBasicSite(url: storiesViewModels[index].url?.absoluteString ?? "",
                                    title: storiesViewModels[index].title)
    }

    // MARK: - Telemetry

    private func recordSectionHasShown() {
        if !hasSentPocketSectionEvent {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .pocketSectionImpression,
                                         value: nil,
                                         extras: nil)
            hasSentPocketSectionEvent = true
        }
    }

    private func recordTapOnStory(index: Int) {
        // Pocket site extra
        let key = TelemetryWrapper.EventExtraKey.pocketTilePosition.rawValue
        let siteExtra = [key: "\(index)"]

        // Origin extra
        let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        let extras = originExtra.merge(with: siteExtra)

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pocketStory, value: nil, extras: extras)
    }

    // MARK: - Private

    @MainActor
    private func updateData() {
        let stories = dataAdaptor.getMerinoData()
        storiesViewModels = []
        // Add the story in the view models list
        for story in stories {
            bind(storyViewModel: .init(story: story))
        }
    }

    private func bind(storyViewModel: StoryStandardCellViewModel) {
        storyViewModel.onTap = { [weak self] indexPath in
            self?.recordTapOnStory(index: indexPath.row)
            let siteUrl = self?.storiesViewModels[indexPath.row].url
            siteUrl.map { self?.onTapTileAction?($0) }
        }

        storiesViewModels.append(storyViewModel)
    }
}

// MARK: HomeViewModelProtocol
extension StoryViewModel: HomepageViewModelProtocol {
    var sectionType: HomepageSectionType {
        return .merino
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        let textColor = wallpaperManager.currentWallpaper.textColor

        return LabelButtonHeaderViewModel(
            title: HomepageSectionType.merino.title,
            titleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.merino,
            isButtonHidden: true,
            textColor: textColor)
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(LegacyPocketStandardCell.UX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: getWidthDimension(),
            heightDimension: .estimated(LegacyPocketStandardCell.UX.cellHeight)
        )

        let subItems = Array(repeating: item, count: UX.numberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = LegacyPocketStandardCell.UX.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: LegacyPocketStandardCell.UX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .estimated(UX.headerFooterHeight))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]

        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: leadingInset,
                                                        bottom: UX.sectionBottomSpacing,
                                                        trailing: 0)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }

    func numberOfItemsInSection() -> Int {
        return !storiesViewModels.isEmpty ? storiesViewModels.count : 0
    }

    var isEnabled: Bool {
        let isFeatureEnabled = prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        return isFeatureEnabled && MerinoProvider.isLocaleSupported(Locale.current.identifier)
    }

    var hasData: Bool {
        return !storiesViewModels.isEmpty
    }

    func screenWasShown() {
        hasSentPocketSectionEvent = false
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

// MARK: FxHomeSectionHandler
extension StoryViewModel: HomepageSectionHandler {
    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        recordSectionHasShown()

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LegacyPocketStandardCell.cellIdentifier,
                                                            for: indexPath) as? LegacyPocketStandardCell else {
            logger.log("Failed to dequeue LegacyPocketStandardCell at indexPath: \(indexPath)",
                       level: .fatal,
                       category: .legacyHomepage)
            return UICollectionViewCell()
        }
        let viewModel = storiesViewModels[indexPath.row]
        viewModel.tag = indexPath.row
        cell.configure(viewModel: viewModel, theme: theme)
        return cell
    }

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        // Setup is done through configure(collectionView:indexPath:), shouldn't be called
        return UICollectionViewCell()
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {
        storiesViewModels[indexPath.row].onTap(indexPath)
    }

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath) {
        guard let onLongPressTileAction = onLongPressTileAction else { return }

        let site = getSitesDetail(for: indexPath.row)
        let sourceView = collectionView.cellForItem(at: indexPath)
        onLongPressTileAction(site, sourceView)
    }
}

extension StoryViewModel: StoryDelegate {
    func didLoadNewData() {
        updateData()
        guard isEnabled else { return }
        delegate?.reloadView()
    }
}
