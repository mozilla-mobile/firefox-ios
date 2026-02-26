// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

typealias HomepageSection = HomepageDiffableDataSource.HomeSection
typealias HomepageItem = HomepageDiffableDataSource.HomeItem

/// Holds the data source configuration for the new homepage as part of the rebuild project
final class HomepageDiffableDataSource:
    UICollectionViewDiffableDataSource<HomepageSection, HomepageItem>,
    FeatureFlaggable {
    typealias TextColor = UIColor
    typealias NumberOfTilesPerRow = Int

    enum HomeSection: Hashable {
        case privacyNotice
        case header
        case messageCard
        case topSites(TextColor?, NumberOfTilesPerRow)
        case searchBar
        case jumpBackIn(TextColor?, JumpBackInSectionLayoutConfiguration)
        case bookmarks(TextColor?)
        case pocket(TextColor?)
        case spacer

        var canHandleLongPress: Bool {
            switch self {
            case .topSites, .jumpBackIn, .bookmarks, .pocket:
                return true
            default:
                return false
            }
        }
    }

    enum HomeItem: Hashable, Sendable {
        case header(HeaderState)
        case privacyNotice
        case messageCard(MessageCardConfiguration)
        case topSite(TopSiteConfiguration, TextColor?)
        case topSiteEmpty
        case searchBar
        case jumpBackIn(JumpBackInTabConfiguration)
        case jumpBackInSyncedTab(JumpBackInSyncedTabConfiguration)
        case bookmark(BookmarkConfiguration)
        case merino(MerinoStoryConfiguration)
        case spacer

        static var cellTypes: [ReusableCell.Type] {
            return [
                HomepageHeaderCell.self,
                PrivacyNoticeCell.self,
                HomepageMessageCardCell.self,
                TopSiteCell.self,
                EmptyTopSiteCell.self,
                SearchBarCell.self,
                JumpBackInCell.self,
                SyncedTabCell.self,
                BookmarksCell.self,
                StoryCell.self,
                StoriesFeedCell.self,
                HomepageSpacerCell.self
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
            case .merino:
                return .story
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

        if state.shouldShowPrivacyNotice {
            snapshot.appendSections([.privacyNotice])
            snapshot.appendItems([.privacyNotice], toSection: .privacyNotice)
        }

        if let configuration = state.messageState.messageCardConfiguration {
            snapshot.appendSections([.messageCard])
            snapshot.appendItems([.messageCard(configuration)], toSection: .messageCard)
        }

        if let (topSites, numberOfCellsPerRow) = getTopSites(with: state.topSitesState, and: textColor) {
            snapshot.appendSections([.topSites(textColor, numberOfCellsPerRow)])
            snapshot.appendItems(topSites, toSection: .topSites(textColor, numberOfCellsPerRow))
        }

        if let (tabs, configuration) = getJumpBackInTabs(with: state.jumpBackInState, and: jumpBackInDisplayConfig) {
            snapshot.appendSections([.jumpBackIn(textColor, configuration)])
            snapshot.appendItems(tabs, toSection: .jumpBackIn(textColor, configuration))
        }

        if let bookmarks = getBookmarks(with: state.bookmarkState) {
            snapshot.appendSections([.bookmarks(textColor)])
            snapshot.appendItems(bookmarks, toSection: .bookmarks(textColor))
        }

        if state.shouldShowSpacer {
            snapshot.appendSections([.spacer])
            snapshot.appendItems([.spacer], toSection: .spacer)
        }

        if state.searchState.shouldShowSearchBar {
            snapshot.appendSections([.searchBar])
            snapshot.appendItems([.searchBar], toSection: .searchBar)
        }

        if let stories = getPocketStories(with: state.merinoState) {
            snapshot.appendSections([.pocket(textColor)])
            snapshot.appendItems(stories, toSection: .pocket(textColor))
        }

        apply(snapshot, animatingDifferences: false)
    }

    private func getPocketStories(
        with pocketState: MerinoState
    ) -> [HomepageDiffableDataSource.HomeItem]? {
        let stories: [HomeItem] = pocketState.merinoData.compactMap { .merino($0) }
        guard pocketState.shouldShowSection, !stories.isEmpty else { return nil }
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

class HomepageSpacerCell: UICollectionViewCell, ReusableCell { }
