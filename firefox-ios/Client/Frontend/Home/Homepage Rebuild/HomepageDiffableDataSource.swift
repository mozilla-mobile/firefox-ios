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
    enum HomeSection: Hashable {
        case header
        case topSites
        case pocket(SectionHeaderState)
        case customizeHomepage

        init?(rawValue: Int) {
            switch rawValue {
            case 0: self = .header
            case 1: self = .topSites
            case 2: self = .pocket(SectionHeaderState())
            case 3: self = .customizeHomepage
            default: return nil
            }
        }
    }

    enum HomeItem: Hashable {
        typealias TextColor = UIColor
        case header(TextColor?)
        case topSite(TopSiteState, TextColor?)
        case topSiteEmpty
        case pocket(PocketStoryState)
        case pocketDiscover
        case customizeHomepage

        static var cellTypes: [ReusableCell.Type] {
            return [
                HomepageHeaderCell.self,
                TopSiteCell.self,
                EmptyTopSiteCell.self,
                PocketStandardCell.self,
                PocketDiscoverCell.self,
                CustomizeHomepageSectionCell.self
            ]
        }
    }

    func updateSnapshot(state: HomepageState) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()

        let textColor = state.pocketState.sectionHeaderState.sectionHeaderColor
        snapshot.appendSections([.header, .topSites, .pocket(state.pocketState.sectionHeaderState), .customizeHomepage])
        snapshot.appendItems([.header(textColor)], toSection: .header)

        let topSites: [HomeItem] = state.topSitesState.topSitesData.compactMap { .topSite($0, textColor) }
        snapshot.appendItems(topSites, toSection: .topSites)

        let stories: [HomeItem] = state.pocketState.pocketData.compactMap { .pocket($0) }
        snapshot.appendItems(stories, toSection: .pocket(state.pocketState.sectionHeaderState))
        snapshot.appendItems([.pocketDiscover], toSection: .pocket(state.pocketState.sectionHeaderState))

        snapshot.appendItems([.customizeHomepage], toSection: .customizeHomepage)

        apply(snapshot, animatingDifferences: true)
    }
}
