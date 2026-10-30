// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import UIKit
import XCTest

@testable import Client

final class HomepageLayoutMeasurementCacheTests: XCTestCase {
    private static let topSite = TopSiteConfiguration(
        site: Site.createBasicSite(url: "https://www.mozilla.org", title: "Mozilla")
    )
    private static let bookmark = BookmarkConfiguration(
        site: Site.createBasicSite(url: "https://www.mozilla.org", title: "Mozilla")
    )
    private static let syncedTab = JumpBackInSyncedTabConfiguration(
        titleText: "Synced tab",
        descriptionText: "mozilla.org",
        url: URL(string: "https://www.mozilla.org")!
    )

    // MARK: - Top sites

    func test_topSitesHeight_withEmptyCache_returnsNil() {
        let subject = createSubject()

        XCTAssertNil(subject.height(for: topSitesKey()))
    }

    func test_topSitesHeight_withMatchingKey_returnsStoredHeight() {
        var subject = createSubject()

        subject.setHeight(120, for: topSitesKey())

        XCTAssertEqual(subject.height(for: topSitesKey()), 120)
    }

    func test_topSitesHeight_withChangedKeyField_returnsNil() {
        let variations: [(String, HomepageLayoutMeasurementCache.TopSitesMeasurement.Key)] = [
            ("topSites", topSitesKey(topSites: [])),
            ("numberOfRows", topSitesKey(numberOfRows: 2)),
            ("numberOfTilesPerRow", topSitesKey(numberOfTilesPerRow: 8)),
            ("headerState", topSitesKey(headerState: .jumpBackIn)),
            ("containerWidth", topSitesKey(containerWidth: 390)),
            ("isLandscape", topSitesKey(isLandscape: true)),
            ("shouldShowSection", topSitesKey(shouldShowSection: false)),
            ("shouldShowAddShortcutTile", topSitesKey(shouldShowAddShortcutTile: true)),
            ("contentSizeCategory", topSitesKey(contentSizeCategory: .accessibilityExtraLarge))
        ]

        for (field, key) in variations {
            var subject = createSubject()
            subject.setHeight(120, for: topSitesKey())

            XCTAssertNil(subject.height(for: key), "Expected a cache miss when \(field) changes")
        }
    }

    func test_setTopSitesHeight_withNewKey_replacesPreviousMeasurement() {
        var subject = createSubject()
        let updatedKey = topSitesKey(numberOfRows: 2)

        subject.setHeight(120, for: topSitesKey())
        subject.setHeight(240, for: updatedKey)

        XCTAssertEqual(subject.height(for: updatedKey), 240)
        XCTAssertNil(subject.height(for: topSitesKey()))
    }

    // MARK: - Jump back in

    func test_jumpBackInHeight_withEmptyCache_returnsNil() {
        let subject = createSubject()

        XCTAssertNil(subject.height(for: jumpBackInKey()))
    }

    func test_jumpBackInHeight_withMatchingKey_returnsStoredHeight() {
        var subject = createSubject()

        subject.setHeight(180, for: jumpBackInKey())

        XCTAssertEqual(subject.height(for: jumpBackInKey()), 180)
    }

    func test_jumpBackInHeight_withChangedKeyField_returnsNil() {
        let variations: [(String, HomepageLayoutMeasurementCache.JumpBackInMeasurement.Key)] = [
            ("syncedTabConfig", jumpBackInKey(syncedTabConfig: nil)),
            ("maxNumberOfLocalTabs", jumpBackInKey(maxNumberOfLocalTabs: 4)),
            ("numberOfLocalTabsToShow", jumpBackInKey(numberOfLocalTabsToShow: 1)),
            ("headerState", jumpBackInKey(headerState: .bookmarks)),
            ("containerWidth", jumpBackInKey(containerWidth: 390)),
            ("shouldShowSection", jumpBackInKey(shouldShowSection: false)),
            ("contentSizeCategory", jumpBackInKey(contentSizeCategory: .accessibilityExtraLarge))
        ]

        for (field, key) in variations {
            var subject = createSubject()
            subject.setHeight(180, for: jumpBackInKey())

            XCTAssertNil(subject.height(for: key), "Expected a cache miss when \(field) changes")
        }
    }

    func test_setJumpBackInHeight_withNewKey_replacesPreviousMeasurement() {
        var subject = createSubject()
        let updatedKey = jumpBackInKey(numberOfLocalTabsToShow: 1)

        subject.setHeight(180, for: jumpBackInKey())
        subject.setHeight(90, for: updatedKey)

        XCTAssertEqual(subject.height(for: updatedKey), 90)
        XCTAssertNil(subject.height(for: jumpBackInKey()))
    }

    // MARK: - Bookmarks

    func test_bookmarksResult_withEmptyCache_returnsNil() {
        let subject = createSubject()

        XCTAssertNil(subject.result(for: bookmarksKey()))
    }

    func test_bookmarksResult_withMatchingKey_returnsStoredResult() {
        var subject = createSubject()
        let result = HomepageLayoutMeasurementCache.BookmarksMeasurement.Result(
            tallestCellHeight: 100,
            totalHeight: 220
        )

        subject.setResult(result, for: bookmarksKey())

        XCTAssertEqual(subject.result(for: bookmarksKey()), result)
    }

    func test_bookmarksResult_withChangedKeyField_returnsNil() {
        let variations: [(String, HomepageLayoutMeasurementCache.BookmarksMeasurement.Key)] = [
            ("bookmarks", bookmarksKey(bookmarks: [])),
            ("headerState", bookmarksKey(headerState: .jumpBackIn)),
            ("containerWidth", bookmarksKey(containerWidth: 390)),
            ("shouldShowSection", bookmarksKey(shouldShowSection: false)),
            ("contentSizeCategory", bookmarksKey(contentSizeCategory: .accessibilityExtraLarge))
        ]

        for (field, key) in variations {
            var subject = createSubject()
            subject.setResult(bookmarksResult(), for: bookmarksKey())

            XCTAssertNil(subject.result(for: key), "Expected a cache miss when \(field) changes")
        }
    }

    func test_setBookmarksResult_withNewKey_replacesPreviousMeasurement() {
        var subject = createSubject()
        let updatedKey = bookmarksKey(containerWidth: 390)
        let updatedResult = HomepageLayoutMeasurementCache.BookmarksMeasurement.Result(
            tallestCellHeight: 60,
            totalHeight: 140
        )

        subject.setResult(bookmarksResult(), for: bookmarksKey())
        subject.setResult(updatedResult, for: updatedKey)

        XCTAssertEqual(subject.result(for: updatedKey), updatedResult)
        XCTAssertNil(subject.result(for: bookmarksKey()))
    }

    // MARK: - Tracker blocker module

    func test_trackerBlockerModuleHeight_withEmptyCache_returnsNil() {
        let subject = createSubject()

        XCTAssertNil(subject.height(for: trackerBlockerKey()))
    }

    func test_trackerBlockerModuleHeight_withMatchingKey_returnsStoredHeight() {
        var subject = createSubject()

        subject.setHeight(50, for: trackerBlockerKey())

        XCTAssertEqual(subject.height(for: trackerBlockerKey()), 50)
    }

    func test_trackerBlockerModuleHeight_withChangedKeyField_returnsNil() {
        let variations: [(String, HomepageLayoutMeasurementCache.TrackerBlockerModuleMeasurement.Key)] = [
            ("blockedTrackerCount", trackerBlockerKey(blockedTrackerCount: 42)),
            ("cellWidth", trackerBlockerKey(cellWidth: 140)),
            ("contentSizeCategory", trackerBlockerKey(contentSizeCategory: .accessibilityExtraExtraLarge))
        ]

        for (field, key) in variations {
            var subject = createSubject()
            subject.setHeight(50, for: trackerBlockerKey())

            XCTAssertNil(subject.height(for: key), "Expected a cache miss when \(field) changes")
        }
    }

    /// The pill grows past its minimum height with larger dynamic type, so the cached height must not be reused
    func test_trackerBlockerModuleHeight_withLargerContentSizeCategory_returnsMeasurementForThatCategory() {
        var subject = createSubject()
        let largeCategoryKey = trackerBlockerKey(contentSizeCategory: .accessibilityExtraExtraLarge)

        subject.setHeight(50, for: trackerBlockerKey())
        subject.setHeight(96, for: largeCategoryKey)

        XCTAssertEqual(subject.height(for: largeCategoryKey), 96)
        XCTAssertNil(subject.height(for: trackerBlockerKey()))
    }

    func test_setTrackerBlockerModuleHeight_withSameKey_returnsLatestHeight() {
        var subject = createSubject()

        subject.setHeight(50, for: trackerBlockerKey())
        subject.setHeight(72, for: trackerBlockerKey())

        XCTAssertEqual(subject.height(for: trackerBlockerKey()), 72)
    }

    // MARK: - Search bar

    func test_searchBarHeight_withEmptyCache_returnsNil() {
        let subject = createSubject()

        XCTAssertNil(subject.height(for: searchBarKey()))
    }

    func test_searchBarHeight_withMatchingKey_returnsStoredHeight() {
        var subject = createSubject()

        subject.setHeight(44, for: searchBarKey())

        XCTAssertEqual(subject.height(for: searchBarKey()), 44)
    }

    func test_searchBarHeight_withChangedKeyField_returnsNil() {
        let variations: [(String, HomepageLayoutMeasurementCache.SearchBarMeasurement.Key)] = [
            ("shouldShowSearchBar", searchBarKey(shouldShowSearchBar: false)),
            ("containerWidth", searchBarKey(containerWidth: 390)),
            ("contentSizeCategory", searchBarKey(contentSizeCategory: .accessibilityExtraLarge))
        ]

        for (field, key) in variations {
            var subject = createSubject()
            subject.setHeight(44, for: searchBarKey())

            XCTAssertNil(subject.height(for: key), "Expected a cache miss when \(field) changes")
        }
    }

    func test_setSearchBarHeight_withNewKey_replacesPreviousMeasurement() {
        var subject = createSubject()
        let updatedKey = searchBarKey(containerWidth: 390)

        subject.setHeight(44, for: searchBarKey())
        subject.setHeight(66, for: updatedKey)

        XCTAssertEqual(subject.height(for: updatedKey), 66)
        XCTAssertNil(subject.height(for: searchBarKey()))
    }

    // MARK: - Cross section

    func test_measurements_areStoredIndependentlyPerSection() {
        var subject = createSubject()

        subject.setHeight(120, for: topSitesKey())
        subject.setHeight(180, for: jumpBackInKey())
        subject.setResult(bookmarksResult(), for: bookmarksKey())
        subject.setHeight(50, for: trackerBlockerKey())
        subject.setHeight(44, for: searchBarKey())

        XCTAssertEqual(subject.height(for: topSitesKey()), 120)
        XCTAssertEqual(subject.height(for: jumpBackInKey()), 180)
        XCTAssertEqual(subject.result(for: bookmarksKey()), bookmarksResult())
        XCTAssertEqual(subject.height(for: trackerBlockerKey()), 50)
        XCTAssertEqual(subject.height(for: searchBarKey()), 44)
    }

    func test_invalidatingOneSection_keepsOtherSectionMeasurements() {
        var subject = createSubject()
        subject.setHeight(50, for: trackerBlockerKey())
        subject.setHeight(44, for: searchBarKey())

        subject.setHeight(96, for: trackerBlockerKey(contentSizeCategory: .accessibilityExtraExtraLarge))

        XCTAssertEqual(subject.height(for: searchBarKey()), 44)
    }

    /// The cache is a value type, so a copy taken before a write must not observe it
    func test_cache_hasValueSemantics() {
        var subject = createSubject()
        subject.setHeight(50, for: trackerBlockerKey())

        let copy = subject
        subject.setHeight(96, for: trackerBlockerKey())

        XCTAssertEqual(copy.height(for: trackerBlockerKey()), 50)
        XCTAssertEqual(subject.height(for: trackerBlockerKey()), 96)
    }

    // MARK: - Helpers

    private func createSubject() -> HomepageLayoutMeasurementCache {
        return HomepageLayoutMeasurementCache()
    }

    private func topSitesKey(
        topSites: [TopSiteConfiguration] = [HomepageLayoutMeasurementCacheTests.topSite],
        numberOfRows: Int = 1,
        numberOfTilesPerRow: Int = 4,
        headerState: SectionHeaderConfiguration = .topSites,
        containerWidth: Double = 320,
        isLandscape: Bool = false,
        shouldShowSection: Bool = true,
        shouldShowAddShortcutTile: Bool = false,
        contentSizeCategory: UIContentSizeCategory = .large
    ) -> HomepageLayoutMeasurementCache.TopSitesMeasurement.Key {
        return HomepageLayoutMeasurementCache.TopSitesMeasurement.Key(
            topSites: topSites,
            numberOfRows: numberOfRows,
            numberOfTilesPerRow: numberOfTilesPerRow,
            headerState: headerState,
            containerWidth: containerWidth,
            isLandscape: isLandscape,
            shouldShowSection: shouldShowSection,
            shouldShowAddShortcutTile: shouldShowAddShortcutTile,
            contentSizeCategory: contentSizeCategory
        )
    }

    private func jumpBackInKey(
        syncedTabConfig: JumpBackInSyncedTabConfiguration? = HomepageLayoutMeasurementCacheTests.syncedTab,
        maxNumberOfLocalTabs: Int = 2,
        numberOfLocalTabsToShow: Int = 2,
        headerState: SectionHeaderConfiguration = .jumpBackIn,
        containerWidth: Double = 320,
        shouldShowSection: Bool = true,
        contentSizeCategory: UIContentSizeCategory = .large
    ) -> HomepageLayoutMeasurementCache.JumpBackInMeasurement.Key {
        return HomepageLayoutMeasurementCache.JumpBackInMeasurement.Key(
            syncedTabConfig: syncedTabConfig,
            maxNumberOfLocalTabs: maxNumberOfLocalTabs,
            numberOfLocalTabsToShow: numberOfLocalTabsToShow,
            headerState: headerState,
            containerWidth: containerWidth,
            shouldShowSection: shouldShowSection,
            contentSizeCategory: contentSizeCategory
        )
    }

    private func bookmarksKey(
        bookmarks: [BookmarkConfiguration] = [HomepageLayoutMeasurementCacheTests.bookmark],
        headerState: SectionHeaderConfiguration = .bookmarks,
        containerWidth: Double = 320,
        shouldShowSection: Bool = true,
        contentSizeCategory: UIContentSizeCategory = .large
    ) -> HomepageLayoutMeasurementCache.BookmarksMeasurement.Key {
        return HomepageLayoutMeasurementCache.BookmarksMeasurement.Key(
            bookmarks: bookmarks,
            headerState: headerState,
            containerWidth: containerWidth,
            shouldShowSection: shouldShowSection,
            contentSizeCategory: contentSizeCategory
        )
    }

    private func bookmarksResult() -> HomepageLayoutMeasurementCache.BookmarksMeasurement.Result {
        return HomepageLayoutMeasurementCache.BookmarksMeasurement.Result(
            tallestCellHeight: 100,
            totalHeight: 220
        )
    }

    private func trackerBlockerKey(
        blockedTrackerCount: Int = 0,
        cellWidth: Double = 320,
        contentSizeCategory: UIContentSizeCategory = .large
    ) -> HomepageLayoutMeasurementCache.TrackerBlockerModuleMeasurement.Key {
        return HomepageLayoutMeasurementCache.TrackerBlockerModuleMeasurement.Key(
            blockedTrackerCount: blockedTrackerCount,
            cellWidth: cellWidth,
            contentSizeCategory: contentSizeCategory
        )
    }

    private func searchBarKey(
        shouldShowSearchBar: Bool = true,
        containerWidth: Double = 320,
        contentSizeCategory: UIContentSizeCategory = .large
    ) -> HomepageLayoutMeasurementCache.SearchBarMeasurement.Key {
        return HomepageLayoutMeasurementCache.SearchBarMeasurement.Key(
            shouldShowSearchBar: shouldShowSearchBar,
            containerWidth: containerWidth,
            contentSizeCategory: contentSizeCategory
        )
    }
}
