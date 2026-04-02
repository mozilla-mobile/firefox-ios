// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import UIKit
/// Holds section layout logic for the new homepage as part of the rebuild project
@MainActor
final class HomepageSectionLayoutProvider: FeatureFlaggable {
    struct UX {
        static let topSpacing: CGFloat = 40
        static let standardInset: CGFloat = 16
        static let standardSpacing: CGFloat = 16
        static let interGroupSpacing: CGFloat = 8
        static let iPadInset: CGFloat = 50
        static let spacingBetweenSections: CGFloat = 44
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
            static let estimatedHeight: CGFloat = 40
            static let bottomSpacing: CGFloat = 30
        }

        struct PrivacyNoticeConstants {
            static let bottomInsets: CGFloat = 24
        }

        struct MessageCardConstants {
            static let height: CGFloat = 180
        }

        struct PocketConstants {
            static let preferredCellSize = CGSize(width: 361, height: 282)
            static let numberOfItemsInColumn = 1
            static let minimumCellHeight: CGFloat = 70
            static let minimumCellWidth: CGFloat = 320
            static let verticalStoriesCellEstimatedHeight: CGFloat = 282
            static let fractionalWidthiPhonePortrait: CGFloat = 0.84
            static let fractionalWidthiPhoneLandscape: CGFloat = 0.37
            static let storiesSpacing: CGFloat = 12
            static let verticalStoriesSpacing: CGFloat = 16
            static let minimumCellsPerRow = 1
            static let interItemSpacing: CGFloat = 16
            static let interGroupSpacing: CGFloat = 16

            /// `storiesPeekOffset` is how much we want the stories section (not including section header)
            /// to peek in vertically from the bottom of the homepage viewport
            static let storiesPeekOffset: CGFloat = 16
            static let storiesPeekOffsetiPad: CGFloat = 36

            @MainActor
            static func getAbsoluteCellWidth(device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
                                             isLandscape: Bool = UIDevice.current.orientation.isLandscape,
                                             collectionViewWidth: CGFloat) -> CGFloat {
                var fractionalWidth: CGFloat
                if device == .pad {
                    return UX.PocketConstants.preferredCellSize.width
                } else if isLandscape {
                    fractionalWidth = UX.PocketConstants.fractionalWidthiPhoneLandscape
                } else {
                    fractionalWidth = UX.PocketConstants.fractionalWidthiPhonePortrait
                }

                return collectionViewWidth * fractionalWidth
            }

            @MainActor
            static func getStoriesCellWidth(for environment: NSCollectionLayoutEnvironment,
                                            isHomepageStoriesScrollDirectionVertical: Bool) -> CGFloat {
                let containerWidth = environment.container.contentSize.width
                if isHomepageStoriesScrollDirectionVertical {
                    let leadingInset = UX.leadingInset(traitCollection: environment.traitCollection)
                    return max(0, containerWidth - (leadingInset * 2))
                }

                return UX.PocketConstants.getAbsoluteCellWidth(collectionViewWidth: containerWidth)
            }

            @MainActor
            static func getStoriesPeekOffset(
                device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
            ) -> CGFloat {
                return device == .pad ? UX.PocketConstants.storiesPeekOffsetiPad : UX.PocketConstants.storiesPeekOffset
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
            static let cellWidth: CGFloat = 134
        }
    }

    private enum StoriesHeaderHeightMode: Equatable {
        case sectionTitle
        case newsAffordance
    }

    private struct StoriesHeaderLayoutState: Equatable {
        let headerHeightMode: StoriesHeaderHeightMode
        let appliedPeekOffset: CGFloat
    }

    private var logger: Logger
    private var windowUUID: WindowUUID

    /// Each section stores a single cached measurement keyed by the layout inputs (including
    /// dynamic type) so that we can detect when the environment has changed. The keys capture
    /// the relevant state for each section, preventing stale heights from being reused when any
    /// of the inputs differ between layout passes.
    private var measurementsCache = HomepageLayoutMeasurementCache()

    private var storiesScrollDirection: ScrollDirection {
        return featureFlags.getCustomState(for: .homepageStoriesScrollDirection) ?? .baseline
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
        case .header:
            return createHeaderSectionLayout(for: environment)
        case .privacyNotice:
            return createSingleItemSectionLayout(
                for: traitCollection,
                bottomInsets: UX.PrivacyNoticeConstants.bottomInsets
            )
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
        case .topSites(_, let numberOfTilesPerRow, let shouldShowSectionHeader):
            return createTopSitesSectionLayout(
                for: traitCollection,
                numberOfTilesPerRow: numberOfTilesPerRow,
                shouldShowSectionHeader: shouldShowSectionHeader
            )
        case .jumpBackIn(_, let configuration):
            return createJumpBackInSectionLayout(
                for: traitCollection,
                config: configuration
            )
        case .pocket:
            return createStoriesSectionLayout(for: environment)
        case .bookmarks:
            return createBookmarksSectionLayout(for: environment)
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

    private func createHeaderSectionLayout(
        for environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(UX.HeaderConstants.estimatedHeight),
                                              heightDimension: .estimated(UX.standardSingleItemHeight))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(UX.HeaderConstants.estimatedHeight),
                                               heightDimension: .estimated(UX.standardSingleItemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let containerWidth = environment.container.contentSize.width
        let effectiveInsets = environment.container.effectiveContentInsets
        let headerWidth = HomepageHeaderCell.UX.contentWidth()
        let availableWidth = max(0, containerWidth - effectiveInsets.leading - effectiveInsets.trailing)
        let horizontalInset = max(0, (availableWidth - headerWidth) / 2)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: horizontalInset,
            bottom: UX.spacingBetweenSections,
            trailing: horizontalInset)

        return section
    }

    private func createStoriesSectionLayout(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        if isHomepageStoriesScrollDirectionVertical {
            return createVerticalStoriesSectionLayout(for: environment)
        }

        return createHorizontalStoriesSectionLayout(for: environment)
    }

    private func createHorizontalStoriesSectionLayout(
        for environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let traitCollection = environment.traitCollection
        let cellWidth = UX.PocketConstants.getStoriesCellWidth(
            for: environment,
            isHomepageStoriesScrollDirectionVertical: isHomepageStoriesScrollDirectionVertical)
        let storiesMeasurement = getStoriesMeasurement(
            environment: environment,
            cellWidth: cellWidth
        )
        let tallestCellHeight = storiesMeasurement.tallestCellHeight
        let cellHeight = max(tallestCellHeight, UX.PocketConstants.minimumCellHeight)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellWidth),
            heightDimension: .absolute(cellHeight)
        )

        let subItems = Array(repeating: item, count: UX.PocketConstants.numberOfItemsInColumn)
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

    private func createVerticalStoriesSectionLayout(
        for environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let itemSize: NSCollectionLayoutSize
        let traitCollection = environment.traitCollection
        let storiesHeaderState = MerinoState.Constants.sectionHeaderConfiguration

        let containerWidth = environment.container.effectiveContentSize.width
        let horizontalInset = UX.leadingInset(traitCollection: traitCollection)
        let cellCount = HomepageDimensionCalculator.numberOfCellsThatFit(in: containerWidth,
                                                                         horizontalInset: horizontalInset)

        // For iOS 17+ we use uniform height across cells in the same group (row) which is the height of the tallest cell
        // in the group.
        // For iOS 16 and earlier, we allow the cell to grow as big as it needs to show it's content, often resulting in
        // groups of cells with uneven heights
        if #available(iOS 17.0, *) {
            itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .uniformAcrossSiblings(estimate: UX.PocketConstants.preferredCellSize.height)
            )
        } else {
            itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(UX.PocketConstants.preferredCellSize.height)
            )
        }

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(UX.PocketConstants.preferredCellSize.height)
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: cellCount
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.PocketConstants.interItemSpacing)

        let section = NSCollectionLayoutSection(group: group)

        let headerFooterSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(getHeaderHeight(headerState: storiesHeaderState, environment: environment))
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: horizontalInset,
            bottom: UX.standardInset,
            trailing: horizontalInset
        )
        section.interGroupSpacing = UX.interGroupSpacing

        return section
    }

    private func createTopSitesSectionLayout(
        for traitCollection: UITraitCollection,
        numberOfTilesPerRow: Int,
        shouldShowSectionHeader: Bool
    ) -> NSCollectionLayoutSection {
        let section = TopSitesSectionLayoutProvider.createTopSitesSectionLayout(for: traitCollection,
                                                                                numberOfTilesPerRow: numberOfTilesPerRow)

        if shouldShowSectionHeader {
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
        }

        let bottomInset = UX.spacingBetweenSections
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

    private func createBookmarksSectionLayout(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let cellWidth = UX.BookmarksConstants.cellWidth

        let bookmarksMeasurement = getBookmarksMeasurement(environment: environment, cellWidth: cellWidth)
        let tallestCellHeight = bookmarksMeasurement.tallestCellHeight

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellWidth),
            heightDimension: .absolute(tallestCellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(cellWidth),
            heightDimension: .absolute(tallestCellHeight)
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

        let leadingInset = UX.leadingInset(traitCollection: environment.traitCollection)
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
        let rawSpacerHeight = getRawSpacerHeight(environment: environment)
        let storiesHeaderLayoutState = getStoriesHeaderLayoutState(environment: environment)

        // Dimensions of <= 0.0 cause runtime warnings, so use a minimum height of 0.1
        var spacerHeight = max(0.1, rawSpacerHeight)

        // For vertically scrolling stories, apply the appropriate peek treatment only when there is spare vertical space.
        // If there isn’t enough room, stories flow naturally after the preceding content with no peeking.
        if rawSpacerHeight > 0, isHomepageStoriesScrollDirectionVertical {
            if storiesHeaderLayoutState.headerHeightMode == .sectionTitle {
                spacerHeight = 0.1
            } else {
                let headerHeight = HomepageDimensionCalculator.fittingHeight(for: NewsTransitionHeaderView(),
                                                                             width: environment.container.contentSize.width)
                spacerHeight = max(0.1, rawSpacerHeight - headerHeight - UX.PocketConstants.getStoriesPeekOffset())
            }
        }

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

    private func getHeaderLogoHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        guard let state = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID) else {
            return 0
        }

        var totalHeight: CGFloat = 0
        let containerWidth = normalizedDimension(environment.container.contentSize.width)

        let headerLogoCell = HomepageHeaderCell()
        headerLogoCell.configure(headerState: state.headerState)
        totalHeight += HomepageDimensionCalculator.fittingHeight(for: headerLogoCell, width: containerWidth)
        totalHeight += UX.spacingBetweenSections
        return totalHeight
    }

    private func getPrivacyNoticeSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        // Ensures we should be showing the privacy notice
        guard let state = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID),
              state.shouldShowPrivacyNotice else { return 0 }

        var totalHeight: CGFloat = 0
        let containerWidth = normalizedDimension(environment.container.contentSize.width)

        let privacyNoticeCell = PrivacyNoticeCell()
        totalHeight += HomepageDimensionCalculator.fittingHeight(for: privacyNoticeCell, width: containerWidth)
        totalHeight += UX.PrivacyNoticeConstants.bottomInsets
        return totalHeight
    }

    /// Creates a "dummy" top sites section and returns its height
    private func getShortcutsSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        guard let state = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID),
              state.topSitesState.shouldShowSection else { return 0 }
        var totalHeight: CGFloat = 0
        let topSitesState = state.topSitesState
        let containerWidth = normalizedDimension(environment.container.contentSize.width)
        let contentSizeCategory = environment.traitCollection.preferredContentSizeCategory
        let measurementKey = HomepageLayoutMeasurementCache.TopSitesMeasurement.Key(
            topSites: topSitesState.topSitesData,
            numberOfRows: topSitesState.numberOfRows,
            numberOfTilesPerRow: topSitesState.numberOfTilesPerRow,
            headerState: TopSitesSectionState.Constants.sectionHeaderConfiguration,
            containerWidth: containerWidth,
            isLandscape: UIDevice.current.orientation.isLandscape,
            shouldShowSection: topSitesState.shouldShowSection,
            contentSizeCategory: contentSizeCategory
        )

        // Reuse the cached result when the key matches, overwrite it when inputs change.
        if let cachedHeight = measurementsCache.height(for: measurementKey) {
                    return cachedHeight
        }

        guard topSitesState.shouldShowSection else {
            measurementsCache.setHeight(0, for: measurementKey)
            return 0
        }
        let maxRows = topSitesState.numberOfRows
        let cols = topSitesState.numberOfTilesPerRow
        let maxCells = maxRows * cols

        guard maxRows > 0, cols > 0, maxCells > 0 else {
            measurementsCache.setHeight(0, for: measurementKey)
            return 0
        }

        let cellsData = topSitesState.topSitesData.prefix(maxCells)
        guard !cellsData.isEmpty else {
            measurementsCache.setHeight(0, for: measurementKey)
            return 0
        }

        // Add header height
        if topSitesState.shouldShowSectionHeader {
            totalHeight += getHeaderHeight(
                headerState: TopSitesSectionState.Constants.sectionHeaderConfiguration,
                environment: environment
            )
        }

        // Build array of configured cells for the data being displayed on the homepage
        let allCells = cellsData.map { data in
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
        let totalRows = Int(ceil(Double(allCells.count) / Double(cols)))
        let presentedRows = min(maxRows, totalRows)
        totalHeight += CGFloat(max(presentedRows - 1, 0)) * UX.standardSpacing

        // Add section insets
        totalHeight += UX.spacingBetweenSections
        measurementsCache.setHeight(totalHeight, for: measurementKey)

        return totalHeight
    }

    /// Creates a "dummy" jump back in section and returns its height
    private func getJumpBackInSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        // Ensures we have at least 1 jump back in tab to show
        guard let state = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID) else {
            return 0
        }

        let jumpBackInState = state.jumpBackInState
        guard jumpBackInState.shouldShowSection,
              jumpBackInState.mostRecentSyncedTab != nil || !jumpBackInState.jumpBackInTabs.isEmpty else { return 0 }

        let containerWidth = normalizedDimension(environment.container.contentSize.width)
        let jumpBackInConfig = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: environment.traitCollection
        )
        let numberOfLocalTabsToShow = min(
            jumpBackInConfig.getMaxNumberOfLocalTabsLayout,
            jumpBackInState.jumpBackInTabs.count
        )

        let key = HomepageLayoutMeasurementCache.JumpBackInMeasurement.Key(
            syncedTabConfig: jumpBackInState.mostRecentSyncedTab,
            maxNumberOfLocalTabs: jumpBackInConfig.getMaxNumberOfLocalTabsLayout,
            numberOfLocalTabsToShow: numberOfLocalTabsToShow,
            headerState: JumpBackInSectionState.Constants.sectionHeaderConfiguration,
            containerWidth: containerWidth,
            shouldShowSection: jumpBackInState.shouldShowSection,
            contentSizeCategory: environment.traitCollection.preferredContentSizeCategory
        )

        // Reuse the cached result when the key matches
        if let cachedHeight = measurementsCache.height(for: key) {
            return cachedHeight
        }

        // Calculate jump back in sections new height
        var totalHeight: CGFloat = 0
        var totalCells = 0

        // Add height of synced tab cell (if it exists)
        if let syncedTabConfig = jumpBackInState.mostRecentSyncedTab {
            let syncedTabCell = SyncedTabCell()
            syncedTabCell.configure(configuration: syncedTabConfig,
                                    theme: LightTheme(),
                                    onTapShowAllAction: nil,
                                    onOpenSyncedTabAction: nil)
            let syncedTabCellHeight = HomepageDimensionCalculator.fittingHeight(for: syncedTabCell,
                                                                                width: containerWidth)
            totalCells += 1
            totalHeight += syncedTabCellHeight
        }

        // Add height of local tab cell(s) (if they exists)
        for i in 0..<jumpBackInConfig.getMaxNumberOfLocalTabsLayout {
            if let tabConfig = jumpBackInState.jumpBackInTabs[safe: i] {
                let jumpBackInCell = JumpBackInCell()
                jumpBackInCell.configure(config: tabConfig, theme: LightTheme())
                let jumpBackInCellHeight = HomepageDimensionCalculator.fittingHeight(for: jumpBackInCell,
                                                                                     width: containerWidth)
                totalCells += 1
                totalHeight += jumpBackInCellHeight
            }
        }

        // Add group spacing
        totalHeight += totalCells > 1 ? UX.interGroupSpacing : 0

        // Add header height
        totalHeight += getHeaderHeight(
            headerState: JumpBackInSectionState.Constants.sectionHeaderConfiguration,
            environment: environment
        )

        // Add section insets
        totalHeight += UX.spacingBetweenSections

        // Save cached section height
        measurementsCache.setHeight(totalHeight, for: key)

        return totalHeight
    }

    /// Creates a "dummy" bookmarks section and returns its height
    private func getBookmarksSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        let cellWidth = UX.BookmarksConstants.cellWidth
        let bookmarksMeasurement = getBookmarksMeasurement(environment: environment, cellWidth: cellWidth)
        return bookmarksMeasurement.totalHeight
    }

    /// Creates a "dummy" stories section and returns its height
    private func getStoriesSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        guard let state = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID) else {
            return 0
        }

        let storiesState = state.merinoState
        guard storiesState.shouldShowSection,
              storiesState.hasMerinoResponseContent
        else { return 0 }

        let cellWidth = UX.PocketConstants.getStoriesCellWidth(
            for: environment,
            isHomepageStoriesScrollDirectionVertical: isHomepageStoriesScrollDirectionVertical)
        let storiesMeasurement = getStoriesMeasurement(
            environment: environment,
            cellWidth: cellWidth
        )
        return storiesMeasurement.totalHeight
    }

    /// Creates a "dummy" search bar section and returns its height
    private func getSearchBarSectionHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        guard let state = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID) else {
            return 0
        }

        let searchState = state.searchState
        let containerWidth = normalizedDimension(environment.container.contentSize.width)
        let measurementKey = HomepageLayoutMeasurementCache.SearchBarMeasurement.Key(
            shouldShowSearchBar: searchState.shouldShowSearchBar,
            containerWidth: containerWidth,
            contentSizeCategory: environment.traitCollection.preferredContentSizeCategory
        )

        // Reuse the cached result when the key matches, overwrite it when inputs change.
        if let cachedHeight = measurementsCache.height(for: measurementKey) {
            return cachedHeight
        }

        guard searchState.shouldShowSearchBar else {
            measurementsCache.setHeight(0, for: measurementKey)
            return 0
        }

        let searchBarCell = SearchBarCell()
        let width = environment.container.contentSize.width
        let searchBarHeight = searchBarCell.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        var totalHeight: CGFloat = searchBarHeight
        totalHeight += UX.standardInset
        totalHeight += UX.HeaderConstants.bottomSpacing

        measurementsCache.setHeight(totalHeight, for: measurementKey)

        return totalHeight
    }

    /// Creates a "dummy" header and returns its height
    private func getHeaderHeight(
        headerState: SectionHeaderConfiguration,
        environment: NSCollectionLayoutEnvironment
    ) -> CGFloat {
        let containerWidth = environment.container.contentSize.width
        let headerHeight: CGFloat

        switch headerState.style {
        case .newsAffordance
            where getStoriesHeaderLayoutState(environment: environment).headerHeightMode == .newsAffordance:
            let header = NewsTransitionHeaderView(frame: CGRect(width: 200, height: 200))
            header.configure(state: headerState, textColor: .black, theme: LightTheme(), transitionEnabled: true)
            headerHeight = HomepageDimensionCalculator.fittingHeight(for: header, width: containerWidth)

        default:
            let header = LabelButtonHeaderView(frame: CGRect(width: 200, height: 200))
            header.configure(state: headerState, textColor: .black, theme: LightTheme())
            headerHeight = HomepageDimensionCalculator.fittingHeight(for: header, width: containerWidth)
        }

        return headerHeight
    }

    /// Resolves how the vertical stories header should be presented from the amount of free
    /// space available at the bottom of the unscrolled homepage.
    ///
    /// When there is enough space for the full news affordance peek, we use the affordance-height
    /// header and the full affordance peek offset. If there is only enough space to show the
    /// affordance itself, we still use the affordance-height header but only peek by the available
    /// space. If there is less space than the affordance needs, we fall back to the section-title
    /// header and remove the spacer peek entirely.
    private func getStoriesHeaderLayoutState(
        environment: NSCollectionLayoutEnvironment
    ) -> StoriesHeaderLayoutState {
        let rawSpacerHeight = getRawSpacerHeight(environment: environment)
        guard isHomepageStoriesScrollDirectionVertical else {
            return StoriesHeaderLayoutState(
                headerHeightMode: .sectionTitle,
                appliedPeekOffset: 0
            )
        }

        let newsAffordanceHeaderHeight = HomepageDimensionCalculator
            .fittingHeight(for: NewsTransitionHeaderView(), width: environment.container.contentSize.width)
        let fullPeekOffset = newsAffordanceHeaderHeight + UX.PocketConstants.getStoriesPeekOffset()

        if rawSpacerHeight >= fullPeekOffset {
            // Enough free space to show the full affordance header and the full peek offset.
            return StoriesHeaderLayoutState(
                headerHeightMode: .newsAffordance,
                appliedPeekOffset: fullPeekOffset
            )
        }

        if rawSpacerHeight >= newsAffordanceHeaderHeight {
            // Enough space to show the affordance itself, but not enough for the full peek offset.
            return StoriesHeaderLayoutState(
                headerHeightMode: .newsAffordance,
                appliedPeekOffset: rawSpacerHeight
            )
        }

        // Not enough space for the affordance, so fall back to the section-title header with no peek.
        return StoriesHeaderLayoutState(
            headerHeightMode: .sectionTitle,
            appliedPeekOffset: 0
        )
    }

    private func getRawSpacerHeight(environment: NSCollectionLayoutEnvironment) -> CGFloat {
        let homepageState = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID)
        let collectionViewHeight = environment.container.contentSize.height

        let availableContentHeight = homepageState?.availableContentHeight ?? 0
        let height = availableContentHeight > 0 ? availableContentHeight : collectionViewHeight

        let headerLogoHeight = getHeaderLogoHeight(environment: environment)
        let privacyNoticeHeight = getPrivacyNoticeSectionHeight(environment: environment)
        let topSitesHeight = getShortcutsSectionHeight(environment: environment)
        let jumpBackInHeight = getJumpBackInSectionHeight(environment: environment)
        let bookmarksHeight = getBookmarksSectionHeight(environment: environment)
        let storiesHeight = isHomepageStoriesScrollDirectionVertical ? 0 : getStoriesSectionHeight(environment: environment)
        let searchBarHeight = getSearchBarSectionHeight(environment: environment)

        return height
            - UX.topSpacing
            - headerLogoHeight
            - privacyNoticeHeight
            - topSitesHeight
            - jumpBackInHeight
            - bookmarksHeight
            - searchBarHeight
            - storiesHeight
    }

    /// Gets the bookmarks measurement (tallest cell height and section height)
    private func getBookmarksMeasurement(environment: NSCollectionLayoutEnvironment,
                                         cellWidth: CGFloat) -> HomepageLayoutMeasurementCache.BookmarksMeasurement.Result {
        guard let state = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID) else {
            return HomepageLayoutMeasurementCache.BookmarksMeasurement.Result(
                tallestCellHeight: 0,
                totalHeight: 0
            )
        }
        let bookmarkState = state.bookmarkState
        let containerWidth = normalizedDimension(environment.container.contentSize.width)
        let key = HomepageLayoutMeasurementCache.BookmarksMeasurement.Key(
            bookmarks: bookmarkState.bookmarks,
            headerState: BookmarksSectionState.Constants.sectionHeaderConfiguration,
            containerWidth: containerWidth,
            shouldShowSection: bookmarkState.shouldShowSection,
            contentSizeCategory: environment.traitCollection.preferredContentSizeCategory
        )

        // Reuse the cached result when the key matches, overwrite it when inputs change.
        if let cachedResult = measurementsCache.result(for: key) {
            return cachedResult
        }

        // If we're not showing the section, or don't have any bookmarks, cache and return 0 for the results
        guard bookmarkState.shouldShowSection, bookmarkState.bookmarks.first != nil else {
            let result = HomepageLayoutMeasurementCache.BookmarksMeasurement.Result(
                tallestCellHeight: 0,
                totalHeight: 0
            )
            measurementsCache.setResult(result, for: key)
            return result
        }

        // Create a cell for each bookmark to be used to calculate the tallest cell height so that we ensure all cells
        // remain uniform
        // TODO: FXIOS-12727 - Investigate replacing this code with `uniformAcrossSiblings` API in iOS 17+
        let bookmarkCells = bookmarkState.bookmarks.map { bookmark in
            let cell = BookmarksCell()
            cell.configure(config: bookmark, theme: LightTheme())
            return cell
        }

        let tallestCellHeight = HomepageDimensionCalculator.getTallestViewHeight(
            views: bookmarkCells,
            viewWidth: cellWidth
        )

        // Get the rest of the section's height and cache and return the results
        let headerHeight = getHeaderHeight(
            headerState: BookmarksSectionState.Constants.sectionHeaderConfiguration,
            environment: environment
        )
        let totalHeight = headerHeight
            + tallestCellHeight
            + UX.spacingBetweenSections

        let result = HomepageLayoutMeasurementCache.BookmarksMeasurement.Result(
            tallestCellHeight: tallestCellHeight,
            totalHeight: totalHeight
        )
        measurementsCache.setResult(result, for: key)
        return result
    }

    // Determines the tallest story cell so that all story cells can have a uniform height. This is accomplished by creating
    // "dummy" (never rendered) cells to determine the height of the tallest cell.
    // Although this calculation occurs every time the layout is updated (with each new HomepageState), no noticeable
    // performance impacts were seen with this O(n) function (where n = number of cells needing to be created, currently 9)
    // TODO: FXIOS-12727 - Investigate replacing this code with `uniformAcrossSiblings` API in iOS 17+
    private func getStoriesMeasurement(
        environment: NSCollectionLayoutEnvironment,
        cellWidth: CGFloat
    ) -> HomepageLayoutMeasurementCache.StoriesMeasurement.Result {
        guard let state = store.state.componentState(HomepageState.self, for: .homepage, window: windowUUID) else {
            return HomepageLayoutMeasurementCache.StoriesMeasurement.Result(
                tallestCellHeight: 0,
                totalHeight: 0
            )
        }

        let merinoState = state.merinoState
        let scrollDirection = storiesScrollDirection
        let key = HomepageLayoutMeasurementCache.StoriesMeasurement.Key(
            stories: merinoState.merinoData,
            headerState: MerinoState.Constants.sectionHeaderConfiguration,
            cellWidth: normalizedDimension(cellWidth),
            containerWidth: normalizedDimension(environment.container.contentSize.width),
            shouldShowSection: merinoState.shouldShowSection,
            contentSizeCategory: environment.traitCollection.preferredContentSizeCategory,
            scrollDirection: scrollDirection
        )

        // Reuse the cached result when the key matches, overwrite it when inputs change.
        if let cachedResult = measurementsCache.result(for: key) {
            return cachedResult
        }

        guard merinoState.shouldShowSection,
              merinoState.hasMerinoResponseContent,
              let stories = merinoState.merinoData.stories
        else {
            let result = HomepageLayoutMeasurementCache.StoriesMeasurement.Result(
                tallestCellHeight: 0,
                totalHeight: 0
            )
            measurementsCache.setResult(result, for: key)
            return result
        }

        let storyCells: [UIView] = stories.map { story in
            let cell = StoryCell()
            cell.configure(story: story, theme: LightTheme())
            return cell
        }

        let tallestCellHeight = HomepageDimensionCalculator.getTallestViewHeight(
            views: storyCells,
            viewWidth: cellWidth
        )

        let headerHeight = getHeaderHeight(
            headerState: MerinoState.Constants.sectionHeaderConfiguration,
            environment: environment
        )
        let totalHeight = headerHeight + max(tallestCellHeight, UX.PocketConstants.minimumCellHeight) + UX.standardInset

        let result = HomepageLayoutMeasurementCache.StoriesMeasurement.Result(
            tallestCellHeight: tallestCellHeight,
            totalHeight: totalHeight
        )
        measurementsCache.setResult(result, for: key)
        return result
    }

    // Round to the nearest thousandth
    private func normalizedDimension(_ value: CGFloat) -> Double {
        return Double((value * 1000).rounded() / 1000)
    }
}
