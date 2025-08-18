// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Holds section layout logic for the new homepage as part of the rebuild project
@MainActor
final class HomepageSectionLayoutProvider: FeatureFlaggable {
    struct UX {
        static let standardInset: CGFloat = 16
        static let standardSpacing: CGFloat = 16
        static let interGroupSpacing: CGFloat = 8
        static let iPadInset: CGFloat = 50
        static let spacingBetweenSections: CGFloat = 62
        static let standardSingleItemHeight: CGFloat = 100
        static let sectionHeaderHeight: CGFloat = 75

        @MainActor
        static func leadingInset(
            traitCollection: UITraitCollection,
            interfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        ) -> CGFloat {
            guard interfaceIdiom != .phone else { return standardInset }

            // Handles multitasking on iPad
            return traitCollection.horizontalSizeClass == .regular ? iPadInset : standardInset
        }

        struct HeaderConstants {
            static let bottomSpacing: CGFloat = 30
        }

        struct MessageCardConstants {
            static let height: CGFloat = 180
        }

        struct PocketConstants {
            static let cellHeight: CGFloat = 112
            static let cellWidth: CGFloat = 350
            static let numberOfItemsInColumn = 3
            static let fractionalWidthiPhonePortrait: CGFloat = 0.90
            static let fractionalWidthiPhoneLandscape: CGFloat = 0.46
            @MainActor static let interItemSpacing = NSCollectionLayoutSpacing.fixed(8)

            // Redesigned stories constants
            static let redesignNumberOfItemsInColumn = 1
            static let redesignedMinimumCellHeight: CGFloat = 70
            static let redesignedFractionalWidthiPhonePortrait: CGFloat = 0.84
            static let redesignedFractionalWidthiPhoneLandscape: CGFloat = 0.37
            static let storiesSpacing: CGFloat = 12

            // The dimension of a cell
            // Fractions for iPhone to only show a slight portion of the next column
            @MainActor
            static func getWidthDimension(device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
                                          isLandscape: Bool = UIWindow.isLandscape) -> NSCollectionLayoutDimension {
                if device == .pad {
                    return .absolute(UX.PocketConstants.cellWidth)
                } else if isLandscape {
                    return .fractionalWidth(UX.PocketConstants.fractionalWidthiPhoneLandscape)
                } else {
                    return .fractionalWidth(UX.PocketConstants.fractionalWidthiPhonePortrait)
                }
            }

            @MainActor
            static func getAbsoluteCellWidth(device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
                                             isLandscape: Bool = UIDevice.current.orientation.isLandscape,
                                             collectionViewWidth: CGFloat) -> CGFloat {
                var fractionalWidth: CGFloat
                if device == .pad {
                    return UX.PocketConstants.cellWidth
                } else if isLandscape {
                    fractionalWidth = UX.PocketConstants.redesignedFractionalWidthiPhoneLandscape
                } else {
                    fractionalWidth = UX.PocketConstants.redesignedFractionalWidthiPhonePortrait
                }

                return collectionViewWidth * fractionalWidth
            }
        }

        struct TopSitesConstants {
            static let redesignedTopSitesBottomSpacingLandscape: CGFloat = 16

            @MainActor
            static func getBottomInset() -> CGFloat {
                if UIDevice.current.orientation.isLandscape {
                    return redesignedTopSitesBottomSpacingLandscape
                } else {
                    return UX.spacingBetweenSections - UX.interGroupSpacing
                }
            }
        }

        struct JumpBackInConstants {
            static let itemHeight: CGFloat = 112
            static let syncedItemHeight: CGFloat = 232
            static let syncedItemCompactHeight: CGFloat = 182
            static let maxItemsPerGroup = 2

            @MainActor
            static func getWidthDimension(
                for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
                layoutType: JumpBackInSectionLayoutConfiguration.LayoutType
            ) -> NSCollectionLayoutDimension {
                if layoutType == .compact {
                    return .fractionalWidth(0.95)
                } else if layoutType == .medium {
                    // Cards need to be less than 1/2 (8/16) wide to account for spacing.
                    // On iPhone they need to be slightly wider to match the spacing of the rest of the UI.
                    return device == .pad ?
                        .fractionalWidth(7.66/16) : .fractionalWidth(7.8/16) // iPad or iPhone in landscape
                } else {
                    // Cards need to be less than 1/3 (8/24) wide to account for spacing.
                    return .fractionalWidth(7.66/24)
                }
            }
        }

        struct BookmarksConstants {
            static let cellHeight: CGFloat = 110
            static let cellWidth: CGFloat = 150
        }
    }

    private var logger: Logger
    private var windowUUID: WindowUUID
    private var isStoriesRedesignEnabled: Bool {
        return featureFlags.isFeatureEnabled(.homepageStoriesRedesign, checking: .buildOnly)
    }

    init(windowUUID: WindowUUID, logger: Logger = DefaultLogger.shared) {
        self.windowUUID = windowUUID
        self.logger = logger
    }

    func createLayoutSection(
        for section: HomepageSection,
        with environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let traitCollection = environment.traitCollection
        switch section {
        case .searchBar:
            return createSingleItemSectionLayout(
                for: traitCollection,
                topInsets: UX.standardInset,
                bottomInsets: UX.HeaderConstants.bottomSpacing
            )
        case .messageCard:
            return createSingleItemSectionLayout(
                for: traitCollection,
                itemHeight: UX.MessageCardConstants.height,
                bottomInsets: UX.spacingBetweenSections
            )
        case .topSites(_, let numberOfTilesPerRow):
            return createTopSitesSectionLayout(
                for: traitCollection,
                numberOfTilesPerRow: numberOfTilesPerRow
            )
        case .jumpBackIn(_, let configuration):
            return createJumpBackInSectionLayout(
                for: traitCollection,
                config: configuration
            )
        case .pocket:
            return isStoriesRedesignEnabled ? createStoriesSectionLayout(for: environment)
                                            : createPocketSectionLayout(for: traitCollection)
        case .customizeHomepage:
            return createSingleItemSectionLayout(
                for: traitCollection,
                topInsets: UX.spacingBetweenSections,
                bottomInsets: UX.spacingBetweenSections
            )
        case .bookmarks:
            return createBookmarksSectionLayout(for: traitCollection)
        case .spacer:
            return createSpacerSectionLayout(for: environment)
        }
    }

    private func createSingleItemSectionLayout(
        for traitCollection: UITraitCollection,
        itemHeight: CGFloat = UX.standardSingleItemHeight,
        topInsets: CGFloat = 0,
        bottomInsets: CGFloat = 0
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(itemHeight))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: topInsets,
            leading: leadingInset,
            bottom: bottomInsets,
            trailing: leadingInset)

        return section
    }

    private func createPocketSectionLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.PocketConstants.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: UX.PocketConstants.getWidthDimension(),
            heightDimension: .estimated(UX.PocketConstants.cellHeight)
        )

        let subItems = Array(repeating: item, count: UX.PocketConstants.numberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = UX.PocketConstants.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: UX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .estimated(UX.sectionHeaderHeight))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: leadingInset,
                                                        bottom: UX.standardInset,
                                                        trailing: 0)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }

    private func createStoriesSectionLayout(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let traitCollection = environment.traitCollection
        let cellWidth = UX.PocketConstants.getAbsoluteCellWidth(
            collectionViewWidth: environment.container.contentSize.width
        )
        let tallestCellHeight = getTallestStoryCellHeight(cellWidth: cellWidth)
        let cellHeight = max(tallestCellHeight, UX.PocketConstants.redesignedMinimumCellHeight)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellWidth),
            heightDimension: .absolute(cellHeight)
        )

        let subItems = Array(repeating: item, count: UX.PocketConstants.redesignNumberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0)

        let section = NSCollectionLayoutSection(group: group)

        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .estimated(UX.sectionHeaderHeight))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: leadingInset,
                                                        bottom: UX.standardInset,
                                                        trailing: UX.standardInset)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = UX.PocketConstants.storiesSpacing
        return section
    }

    private func createTopSitesSectionLayout(
        for traitCollection: UITraitCollection,
        numberOfTilesPerRow: Int
    ) -> NSCollectionLayoutSection {
        let section = TopSitesSectionLayoutProvider.createTopSitesSectionLayout(for: traitCollection,
                                                                                numberOfTilesPerRow: numberOfTilesPerRow)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.sectionHeaderHeight)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        let bottomInset = isStoriesRedesignEnabled ? UX.TopSitesConstants.getBottomInset()
                                                   : UX.spacingBetweenSections - UX.interGroupSpacing
        section.contentInsets.top = 0
        section.contentInsets.bottom = bottomInset

        return section
    }

    private func createCompactJumpBackInSectionLayout(
        widthDimension: NSCollectionLayoutDimension
    ) -> NSCollectionLayoutSection {
        let syncedTabItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.JumpBackInConstants.syncedItemCompactHeight)
        )

        let syncedTabItem = NSCollectionLayoutItem(layoutSize: syncedTabItemSize)

        let jumpBackInItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.JumpBackInConstants.itemHeight)
        )

        let jumpBackInItem = NSCollectionLayoutItem(layoutSize: jumpBackInItemSize)

        let groupHeight: CGFloat = UX.JumpBackInConstants.syncedItemCompactHeight
        + UX.JumpBackInConstants.itemHeight
        + UX.interGroupSpacing

        let groupSize = NSCollectionLayoutSize(
            widthDimension: widthDimension,
            heightDimension: .estimated(groupHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [jumpBackInItem, syncedTabItem]
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.interGroupSpacing)

        return NSCollectionLayoutSection(group: group)
    }

    private func createLargeJumpBackInSectionLayout(
        widthDimension: NSCollectionLayoutDimension,
        numberOfItems: Int,
        hasSyncedTab: Bool
    ) -> NSCollectionLayoutSection {
        let syncedTabItemSize = NSCollectionLayoutSize(
            widthDimension: widthDimension,
            heightDimension: .estimated(UX.JumpBackInConstants.syncedItemHeight)
        )
        let syncedTabItem = NSCollectionLayoutItem(layoutSize: syncedTabItemSize)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.JumpBackInConstants.itemHeight)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // Nested Group (Jump Back In)
        let nestedGroupSize = NSCollectionLayoutSize(
            widthDimension: widthDimension,
            heightDimension: .estimated(UX.JumpBackInConstants.syncedItemHeight)
        )
        let nestedGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: nestedGroupSize,
            subitems: [item, item]
        )
        nestedGroup.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.interGroupSpacing)

        // Main Group
        let mainGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.JumpBackInConstants.syncedItemHeight)
        )

        let numberOfGroups = ceil(Double(numberOfItems) / Double(UX.JumpBackInConstants.maxItemsPerGroup))
        var subItems: [NSCollectionLayoutItem] = Array(repeating: nestedGroup, count: Int(numberOfGroups))

        if hasSyncedTab {
            subItems.insert(syncedTabItem, at: 0)
        }

        let mainGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: mainGroupSize,
            subitems: subItems
        )
        mainGroup.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.interGroupSpacing)

        return NSCollectionLayoutSection(group: mainGroup)
    }

    private func createJumpBackInSectionLayout(
        for traitCollection: UITraitCollection,
        config: JumpBackInSectionLayoutConfiguration
    ) -> NSCollectionLayoutSection {
        var section: NSCollectionLayoutSection
        let widthDimension = UX.JumpBackInConstants.getWidthDimension(layoutType: config.layoutType)
        if config.layoutType == .compact {
            section = createCompactJumpBackInSectionLayout(widthDimension: widthDimension)
        } else {
            section = createLargeJumpBackInSectionLayout(
                widthDimension: widthDimension,
                numberOfItems: config.getMaxNumberOfLocalTabsLayout,
                hasSyncedTab: config.hasSyncedTab ?? false
            )
        }

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.sectionHeaderHeight)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: leadingInset,
                    bottom: UX.spacingBetweenSections,
                    trailing: leadingInset)

        return section
    }

    private func createBookmarksSectionLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(UX.BookmarksConstants.cellWidth),
            heightDimension: .estimated(UX.BookmarksConstants.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(UX.BookmarksConstants.cellWidth),
            heightDimension: .estimated(UX.BookmarksConstants.cellHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.sectionHeaderHeight)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: leadingInset,
            bottom: UX.spacingBetweenSections,
            trailing: leadingInset)

        section.interGroupSpacing = UX.interGroupSpacing
        section.orthogonalScrollingBehavior = .continuous

        return section
    }

    // Creates the spacer section used to achieve a full-screen layout without having a full screen of content.
    // The spacer section's height is manually calculated by summing up every other visible sections height, including it's
    // content, headers/footers, vertical item/group/section spacing, and vertical item/group/section insets.
    // It's important to update this calculation whenever a change is made to any of the calculated sections that would
    // result in it having a different height (eg changes to top/bottom insets).
    private func createSpacerSectionLayout(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let homepageState = store.state.screenState(HomepageState.self, for: .homepage, window: windowUUID)
        let collectionViewHeight = environment.container.contentSize.height

        // If something went wrong with our availableContentHeight calculation in BVC, fall back to just using the actual
        // collection view height
        let availableContentHeight = homepageState?.availableContentHeight ?? collectionViewHeight

        // Dimensions of <= 0.0 cause runtime warnings, so use a minimum height of 0.1
        let spacerHeight = max(0.1, availableContentHeight - getShortcutsSectionHeight(environment: environment)
                                                           - getStoriesSectionHeight(environment: environment)
                                                           - getSearchBarSectionHeight(environment: environment)
        )

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(spacerHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let sectionLayout = NSCollectionLayoutSection(group: group)
        sectionLayout.interGroupSpacing = 0
        return sectionLayout
    }

    /// Returns an empty layout to avoid app crash when unable to section data
    func makeEmptyLayoutSection() -> NSCollectionLayoutSection {
        let zeroLayoutSize = NSCollectionLayoutSize(
            widthDimension: .absolute(0.0),
            heightDimension: .absolute(0.0)
        )
        let emptyGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: zeroLayoutSize,
            subitems: [NSCollectionLayoutItem(layoutSize: zeroLayoutSize)]
        )
        return NSCollectionLayoutSection(group: emptyGroup)
    }

    /// Creates a "dummy" top sites section and returns its height
    private func getShortcutsSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        guard let state = store.state.screenState(HomepageState.self, for: .homepage, window: windowUUID) else { return 0 }
        var totalHeight: CGFloat = 0
        let topSitesState = state.topSitesState
        let maxRows = topSitesState.numberOfRows
        let cols = topSitesState.numberOfTilesPerRow
        let maxCells = maxRows * cols

        // Add header height
        totalHeight += getHeaderHeight(headerState: topSitesState.sectionHeaderState, environment: environment)

        // Build array of configured cells for the data being displayed on the homepage
        let allCells = topSitesState.topSitesData.prefix(maxCells).map { data in
            let cell = TopSiteCell()
            cell.configure(data, position: 0, theme: LightTheme(), textColor: .black)
            return cell
        }

        // Group into rows and compute each rows max height
        let rowHeights = stride(from: 0, to: allCells.count, by: cols).map { start in
            let end = min(start + cols, allCells.count)
            let rowCells = Array(allCells[start..<end])
            return HomepageDimensionCalculator.getTallestViewHeight(views: rowCells, viewWidth: 0)
        }

        // Sum up row heights
        totalHeight += rowHeights.reduce(0, +)

        // Add inter-row spacing
        // Get number of actual rows shown since TopSitesSectionState::numberOfRows just gives us the user pref of max
        // number of rows we can show.
        // totalRows: number of rows we have enough data for
        // presentedRows: number of rows visible in the UI
        let totalRows = Int(ceil(Double(topSitesState.topSitesData.count) / Double(cols)))
        let presentedRows = min(maxRows, totalRows)
        totalHeight += CGFloat(presentedRows - 1) * UX.standardSpacing

        // Add section insets
        totalHeight += UX.TopSitesConstants.getBottomInset()

        return totalHeight
    }

    /// Creates a "dummy" stories section and returns its height
    private func getStoriesSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        guard let state = store.state.screenState(HomepageState.self, for: .homepage, window: windowUUID) else { return 0 }
        var totalHeight: CGFloat = 0
        let storiesState = state.merinoState

        // Add header height
        totalHeight += getHeaderHeight(headerState: storiesState.sectionHeaderState, environment: environment)

        // Add stories height
        let cellWidth = UX.PocketConstants.getAbsoluteCellWidth(
            collectionViewWidth: environment.container.contentSize.width
        )
        totalHeight += max(getTallestStoryCellHeight(cellWidth: cellWidth), UX.PocketConstants.redesignedMinimumCellHeight)

        // Add section insets
        totalHeight += UX.standardInset

        return totalHeight
    }

    /// Creates a "dummy" search bar section and returns its height
    private func getSearchBarSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        guard let state = store.state.screenState(HomepageState.self, for: .homepage, window: windowUUID),
                  state.searchState.shouldShowSearchBar else { return 0 }
        var totalHeight: CGFloat = 0

        // Add search bar height
        let searchBarCell = SearchBarCell()
        let containerWidth = environment.container.contentSize.width
        let searchBarHeight = searchBarCell.systemLayoutSizeFitting(
            CGSize(width: containerWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        totalHeight += searchBarHeight

        // Add section insets
        totalHeight += UX.standardInset
        totalHeight += UX.HeaderConstants.bottomSpacing

        return totalHeight
    }

    /// Creates a "dummy" header and returns it's height
    private func getHeaderHeight(headerState: SectionHeaderConfiguration,
                                 environment: NSCollectionLayoutEnvironment) -> CGFloat {
        let header = LabelButtonHeaderView(frame: CGRect(width: 200, height: 200))
        header.configure(state: headerState, textColor: .black, theme: LightTheme())
        let containerWidth = environment.container.contentSize.width
        let headerHeight = header.systemLayoutSizeFitting(
            CGSize(width: containerWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        return headerHeight
    }

    // Determines the tallest story cell so that all story cells can have a uniform height. This is accomplished by creating
    // "dummy" (never rendered) cells to determine the height of the tallest cell.
    // Although this calculation occurs every time the layout is updated (with each new HomepageState), no noticeable
    // performance impacts were seen with this O(n) function (where n = number of cells needing to be created, currently 9)
    // TODO: FXIOS-12727 - Investigate replacing this code with `uniformAcrossSiblings` API in iOS 17+
    private func getTallestStoryCellHeight(cellWidth: CGFloat) -> CGFloat {
        guard let state = store.state.screenState(HomepageState.self, for: .homepage, window: windowUUID) else { return 0 }
        var storyCells: [StoryCell] = []
        for story in state.merinoState.merinoData {
            let cell = StoryCell()
            cell.configure(story: story, theme: LightTheme())
            storyCells.append(cell)
        }
        return HomepageDimensionCalculator.getTallestViewHeight(views: storyCells, viewWidth: cellWidth)
    }
}
