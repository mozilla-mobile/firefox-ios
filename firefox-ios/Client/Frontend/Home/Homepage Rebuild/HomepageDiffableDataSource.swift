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
        case jumpBackIn
        case bookmarks
        case pocket(TextColor?)
        case customizeHomepage
    }

    enum HomeItem: Hashable {
        case header(HeaderState)
        case messageCard(MessageCardConfiguration)
        case topSite(TopSiteState, TextColor?)
        case topSiteEmpty
        case jumpBackIn(JumpBackInTabState)
        case bookmark(BookmarkState)
        case pocket(PocketStoryState)
        case pocketDiscover(PocketDiscoverState)
        case customizeHomepage

        static var cellTypes: [ReusableCell.Type] {
            return [
                HomepageHeaderCell.self,
                HomepageMessageCardCell.self,
                TopSiteCell.self,
                EmptyTopSiteCell.self,
                JumpBackInCell.self,
                BookmarksCell.self,
                PocketStandardCell.self,
                PocketDiscoverCell.self,
                CustomizeHomepageSectionCell.self
            ]
        }
    }

    func updateSnapshot(state: HomepageState, numberOfCellsPerRow: Int) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()

        let textColor = state.wallpaperState.wallpaperConfiguration.textColor

        snapshot.appendSections([.header])
        snapshot.appendItems([.header(state.headerState)], toSection: .header)

        if let configuration = state.messageState.messageCardConfiguration {
            snapshot.appendSections([.messageCard])
            snapshot.appendItems([.messageCard(configuration)], toSection: .messageCard)
        }

        if let topSites = getTopSites(with: state.topSitesState, and: textColor, numberOfCellsPerRow: numberOfCellsPerRow) {
            snapshot.appendSections([.topSites(numberOfCellsPerRow)])
            snapshot.appendItems(topSites, toSection: .topSites(numberOfCellsPerRow))
        }

        if let tabs = getJumpBackInTabs(with: state.jumpBackInState) {
            snapshot.appendSections([.jumpBackIn])
            snapshot.appendItems(tabs, toSection: .jumpBackIn)
        }

        // TODO: FXIOS-11051 Update showing bookmarks
        snapshot.appendSections([.bookmarks])
        snapshot.appendItems(state.bookmarkState.bookmarks.compactMap { .bookmark($0) }, toSection: .bookmarks)

        if let stories = getPocketStories(with: state.pocketState) {
            snapshot.appendSections([.pocket(textColor)])
            snapshot.appendItems(stories, toSection: .pocket(textColor))
        }

        snapshot.appendSections([.customizeHomepage])
        snapshot.appendItems([.customizeHomepage], toSection: .customizeHomepage)

        apply(snapshot, animatingDifferences: true)
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
        and textColor: TextColor?,
        numberOfCellsPerRow: Int
    ) -> [HomepageDiffableDataSource.HomeItem]? {
        guard topSitesState.shouldShowSection else { return nil }
        let topSites: [HomeItem] = topSitesState.topSitesData.prefix(
            topSitesState.numberOfRows * numberOfCellsPerRow
        ).compactMap {
            .topSite($0, textColor)
        }
        guard !topSites.isEmpty else { return nil }
        return topSites
    }

    private func getJumpBackInTabs(
        with jumpBackInSectionState: JumpBackInSectionState
    ) -> [HomepageDiffableDataSource.HomeItem]? {
        // TODO: FXIOS-11226 Show items or hide items depending user prefs / feature flag
        return jumpBackInSectionState.jumpBackInTabs.compactMap { .jumpBackIn($0) }
    }
}
