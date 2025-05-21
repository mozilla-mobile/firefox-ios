// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

typealias HomepageSection = HomepageDiffableDataSource.HomeSection
typealias HomepageItem = HomepageDiffableDataSource.HomeItem

/// Holds the data source configuration for the new homepage as part of the rebuild project
final class HomepageDiffableDataSource:
    UICollectionViewDiffableDataSource<HomepageSection, HomepageItem> {
    typealias TextColor = UIColor
    typealias NumberOfTilesPerRow = Int

    enum HomeSection: Hashable {
        case header
        case messageCard
        case topSites(NumberOfTilesPerRow)
        case jumpBackIn(TextColor?, JumpBackInSectionLayoutConfiguration)
        case bookmarks(TextColor?)
        case pocket(TextColor?)
        case customizeHomepage

        var canHandleLongPress: Bool {
            switch self {
            case .topSites, .jumpBackIn, .bookmarks, .pocket:
                return true
            default:
                return false
            }
        }
    }

    enum HomeItem: Hashable {
        case header(HeaderState)
        case messageCard(MessageCardConfiguration)
        case topSite(TopSiteConfiguration, TextColor?)
        case topSiteEmpty
        case jumpBackIn(JumpBackInTabConfiguration)
        case jumpBackInSyncedTab(JumpBackInSyncedTabConfiguration)
        case bookmark(BookmarkConfiguration)
        case pocket(PocketStoryConfiguration)
        case pocketDiscover(PocketDiscoverConfiguration)
        case customizeHomepage

        static var cellTypes: [ReusableCell.Type] {
            return [
                HomepageHeaderCell.self,
                HomepageMessageCardCell.self,
                LegacyTopSiteCell.self,
                TopSiteCell.self,
                EmptyTopSiteCell.self,
                JumpBackInCell.self,
                SyncedTabCell.self,
                BookmarksCell.self,
                PocketStandardCell.self,
                PocketDiscoverCell.self,
                CustomizeHomepageSectionCell.self
            ]
        }

        var telemetryItemType: HomepageTelemetry.ItemType? {
            switch self {
            case .topSite:
                return .topSite
            case .jumpBackIn:
                return .jumpBackInTab
            case .jumpBackInSyncedTab:
                return .jumpBackInSyncedTab
            case .bookmark:
                return .bookmark
            case .pocket:
                return .story
            case .pocketDiscover:
                return .storyDiscoverMore
            case .customizeHomepage:
                return .customizeHomepage
            default:
                return nil
            }
        }
    }

    func updateSnapshot(
        state: HomepageState,
        jumpBackInDisplayConfig: JumpBackInSectionLayoutConfiguration
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()

        let textColor = state.wallpaperState.wallpaperConfiguration.textColor

        snapshot.appendSections([.header])
        snapshot.appendItems([.header(state.headerState)], toSection: .header)

        if let configuration = state.messageState.messageCardConfiguration {
            snapshot.appendSections([.messageCard])
            snapshot.appendItems([.messageCard(configuration)], toSection: .messageCard)
        }

        if let (topSites, numberOfCellsPerRow) = getTopSites(with: state.topSitesState, and: textColor) {
            snapshot.appendSections([.topSites(numberOfCellsPerRow)])
            snapshot.appendItems(topSites, toSection: .topSites(numberOfCellsPerRow))
        }

        if let (tabs, configuration) = getJumpBackInTabs(with: state.jumpBackInState, and: jumpBackInDisplayConfig) {
            snapshot.appendSections([.jumpBackIn(textColor, configuration)])
            snapshot.appendItems(tabs, toSection: .jumpBackIn(textColor, configuration))
        }

        if let bookmarks = getBookmarks(with: state.bookmarkState) {
            snapshot.appendSections([.bookmarks(textColor)])
            snapshot.appendItems(bookmarks, toSection: .bookmarks(textColor))
        }

        if let stories = getPocketStories(with: state.pocketState) {
            snapshot.appendSections([.pocket(textColor)])
            snapshot.appendItems(stories, toSection: .pocket(textColor))
        }

        snapshot.appendSections([.customizeHomepage])
        snapshot.appendItems([.customizeHomepage], toSection: .customizeHomepage)

        apply(snapshot, animatingDifferences: false)
    }

    private func getPocketStories(
        with pocketState: PocketState
    ) -> [HomepageDiffableDataSource.HomeItem]? {
        var stories: [HomeItem] = pocketState.pocketData.compactMap { .pocket($0) }
        guard pocketState.shouldShowSection, !stories.isEmpty else { return nil }
        stories.append(.pocketDiscover(pocketState.pocketDiscoverItem))
        return stories
    }

    /// Gets the proper amount of top sites based on layout configuration
    /// which is determined by the number of rows and number of tiles per row
    /// - Parameters:
    ///   - topSiteState: state object for top site section
    ///   - textColor: text color from wallpaper configuration
    private func getTopSites(
        with topSitesState: TopSitesSectionState,
        and textColor: TextColor?
    ) -> ([HomepageDiffableDataSource.HomeItem], Int)? {
        guard topSitesState.shouldShowSection else { return nil }
        let topSites: [HomeItem] = topSitesState.topSitesData.prefix(
            topSitesState.numberOfRows * topSitesState.numberOfTilesPerRow
        ).compactMap {
            .topSite($0, textColor)
        }
        guard !topSites.isEmpty else { return nil }
        return (topSites, topSitesState.numberOfTilesPerRow)
    }

    private func getJumpBackInTabs(
        with state: JumpBackInSectionState,
        and config: JumpBackInSectionLayoutConfiguration
    ) -> ([HomepageDiffableDataSource.HomeItem], JumpBackInSectionLayoutConfiguration)? {
        guard state.shouldShowSection else { return nil }
        var updatedConfig = config
        updatedConfig.hasSyncedTab = state.mostRecentSyncedTab != nil

        var tabs: [HomeItem] = state.jumpBackInTabs
            .prefix(updatedConfig.getMaxNumberOfLocalTabsLayout)
            .compactMap { .jumpBackIn($0) }

        // Determines if remote tab should appear first depending on device size
        if let mostRecentSyncedTab = state.mostRecentSyncedTab {
            if updatedConfig.layoutType == .compact {
                tabs.append(.jumpBackInSyncedTab(mostRecentSyncedTab))
            } else {
                tabs.insert(.jumpBackInSyncedTab(mostRecentSyncedTab), at: 0)
            }
        }
        guard !tabs.isEmpty else { return nil }
        return (tabs, updatedConfig)
    }

    private func getBookmarks(
        with state: BookmarksSectionState
    ) -> [HomepageDiffableDataSource.HomeItem]? {
        guard state.shouldShowSection, !state.bookmarks.isEmpty else { return nil }
        return state.bookmarks.compactMap { .bookmark($0) }
    }
}
