// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct HomepageLayoutMeasurementCache {
    struct TopSitesMeasurement: Equatable {
        struct Key: Equatable {
            let topSites: [TopSiteConfiguration]
            let numberOfRows: Int
            let numberOfTilesPerRow: Int
            let headerState: SectionHeaderConfiguration
            let containerWidth: Double
            let isLandscape: Bool
            let shouldShowSection: Bool
            let contentSizeCategory: UIContentSizeCategory
        }

        let key: Key
        let height: CGFloat
    }

    struct JumpBackInMeasurement: Equatable {
        struct Key: Equatable {
            let syncedTabConfig: JumpBackInSyncedTabConfiguration?
            let maxNumberOfLocalTabs: Int
            let numberOfLocalTabsToShow: Int
            let headerState: SectionHeaderConfiguration
            let containerWidth: Double
            let shouldShowSection: Bool
            let contentSizeCategory: UIContentSizeCategory
        }

        let key: Key
        let height: CGFloat
    }

    struct BookmarksMeasurement: Equatable {
        struct Key: Equatable {
            let bookmarks: [BookmarkConfiguration]
            let headerState: SectionHeaderConfiguration
            let containerWidth: Double
            let shouldShowSection: Bool
            let contentSizeCategory: UIContentSizeCategory
        }

        struct Result: Equatable {
            let tallestCellHeight: CGFloat
            let totalHeight: CGFloat
        }

        let key: Key
        let result: Result
    }

    struct StoriesMeasurement: Equatable {
        struct Key: Equatable {
            let stories: [MerinoStoryConfiguration]
            let headerState: SectionHeaderConfiguration
            let cellWidth: Double
            let containerWidth: Double
            let shouldShowSection: Bool
            let contentSizeCategory: UIContentSizeCategory
            let scrollDirection: ScrollDirection
        }

        struct Result: Equatable {
            let tallestCellHeight: CGFloat
            let totalHeight: CGFloat
        }

        let key: Key
        let result: Result
    }

    struct SearchBarMeasurement: Equatable {
        struct Key: Equatable {
            let shouldShowSearchBar: Bool
            let containerWidth: Double
            let contentSizeCategory: UIContentSizeCategory
        }

        let key: Key
        let height: CGFloat
    }

    private var topSites: TopSitesMeasurement?
    private var jumpBackIn: JumpBackInMeasurement?
    private var bookmarks: BookmarksMeasurement?
    private var stories: StoriesMeasurement?
    private var searchBar: SearchBarMeasurement?

    mutating func setHeight(_ height: CGFloat, for key: TopSitesMeasurement.Key) {
        topSites = TopSitesMeasurement(key: key, height: height)
    }

    func height(for key: TopSitesMeasurement.Key) -> CGFloat? {
        guard let measurement = topSites, measurement.key == key else { return nil }
        return measurement.height
    }

    mutating func setHeight(_ height: CGFloat, for key: SearchBarMeasurement.Key) {
        searchBar = SearchBarMeasurement(key: key, height: height)
    }

    func height(for key: SearchBarMeasurement.Key) -> CGFloat? {
        guard let measurement = searchBar, measurement.key == key else { return nil }
        return measurement.height
    }

    mutating func setHeight(_ height: CGFloat, for key: JumpBackInMeasurement.Key) {
        jumpBackIn = JumpBackInMeasurement(key: key, height: height)
    }

    func height(for key: JumpBackInMeasurement.Key) -> CGFloat? {
        guard let measurement = jumpBackIn, measurement.key == key else { return nil }
        return measurement.height
    }

    mutating func setResult(_ result: BookmarksMeasurement.Result, for key: BookmarksMeasurement.Key) {
        bookmarks = BookmarksMeasurement(key: key, result: result)
    }

    func result(for key: BookmarksMeasurement.Key) -> BookmarksMeasurement.Result? {
        guard let measurement = bookmarks, measurement.key == key else { return nil }
        return measurement.result
    }

    mutating func setResult(_ result: StoriesMeasurement.Result, for key: StoriesMeasurement.Key) {
        stories = StoriesMeasurement(key: key, result: result)
    }

    func result(for key: StoriesMeasurement.Key) -> StoriesMeasurement.Result? {
        guard let measurement = stories, measurement.key == key else { return nil }
        return measurement.result
    }
}
