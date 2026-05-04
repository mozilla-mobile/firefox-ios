// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import WebKit
import Shared
import Common
@testable import Client

final class TabManagerOlderTabsTests: TabManagerTestsBase {
    // MARK: - Remove Tabs Older than

    @MainActor
    func testRemoveNormalTabsOlderThan_whenNotOldNormalTabs_thenNoTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normal, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, numberTabs)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenOlderNormalTabs_thenTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlderLastMonth, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneWeek, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 0)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenPrivateTabs_thenNoTabsRemoved() {
        let numberPrivateTabs = 3
        let tabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenYesterdayNormalTabs_thenTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlderYesterday, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 0)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenYesterdayNormalTabsOlderThanOneWeek_thenTabsNotRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlderYesterday, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneWeek, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, numberTabs)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenYesterdayNormalTabsOlderThanOneMonth_thenTabsNotRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlderYesterday, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneMonth, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, numberTabs)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_when2WeeksNormalTabs_thenTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlder2Weeks, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 0)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_when2WeeksNormalTabsOlderThanOneWeek_thenTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlder2Weeks, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneWeek, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 0)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_when2WeeksNormalTabsOlderThanOneMonth_thenTabsNotRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlder2Weeks, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneMonth, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, numberTabs)
    }

    @MainActor
    func testRemoveNormalsTabsOlderThan_whenSelectedTabIsInTheMiddle_thenOrderIsProper() {
        let olderTabs1 = generateTabs(ofType: .normalOlder2Weeks, count: 10)
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let olderTabs2 = generateTabs(ofType: .normalOlder2Weeks, count: 10)
        let tabManager = createSubject(tabs: olderTabs1 + normalTabs + olderTabs2)
        tabManager.selectTab(normalTabs[safe: 0])

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 3)
        XCTAssertEqual(tabManager.selectedIndex, 0)
    }

    @MainActor
    func testRemoveNormalsTabsOlderThan_whenSelectedTabIsLast_thenOrderIsProper() {
        let olderTabs1 = generateTabs(ofType: .normalOlder2Weeks, count: 10)
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let tabManager = createSubject(tabs: olderTabs1 + normalTabs)
        tabManager.selectTab(normalTabs[safe: 2])

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 3)
        XCTAssertEqual(tabManager.selectedIndex, 2)
    }

    @MainActor
    func testRemoveNormalsTabsOlderThan_whenSelectedTabIsFirst_thenOrderIsProper() {
        let olderTabs1 = generateTabs(ofType: .normalOlder2Weeks, count: 10)
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let tabManager = createSubject(tabs: normalTabs + olderTabs1)
        tabManager.selectTab(normalTabs[safe: 0])

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 3)
        XCTAssertEqual(tabManager.selectedIndex, 0)
    }

    // MARK: - normalTabs / privateTabs cache tests

    @MainActor
    func testNormalAndPrivateTabs_sumEqualsAllTabs() {
        var tabs = generateTabs(ofType: .normal, count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 3))
        let subject = createSubject(tabs: tabs)

        XCTAssertEqual(subject.normalTabs.count + subject.privateTabs.count, subject.tabs.count)
        XCTAssertEqual(subject.normalTabs.count, 5)
        XCTAssertEqual(subject.privateTabs.count, 3)
    }

    @MainActor
    func testNormalTabs_cacheInvalidatedAfterTabAdded() {
        // Cache must be cleared when `tabs` grows, otherwise the new tab is invisible.
        let subject = createSubject(tabs: generateTabs(count: 3))
        XCTAssertEqual(subject.normalTabs.count, 3)

        subject.addTabsForURLs([URL(string: "https://example.com")!], zombie: false)
        XCTAssertEqual(
            subject.normalTabs.count,
            4,
            "normalTabs should reflect the newly added tab after cache invalidation."
        )
    }

    @MainActor
    func testPrivateTabs_cacheInvalidatedAfterTabAdded() {
        let subject = createSubject(tabs: generateTabs(ofType: .privateAny, count: 2))
        XCTAssertEqual(subject.privateTabs.count, 2)

        subject.addTabsForURLs([URL(string: "https://example.com")!], zombie: false, isPrivate: true)
        XCTAssertEqual(
            subject.privateTabs.count,
            3,
            "privateTabs should reflect the newly added tab after cache invalidation."
        )
    }

    @MainActor
    func testNormalTabs_cacheInvalidatedAfterTabRemoved() {
        let tabs = generateTabs(count: 3)
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.normalTabs.count, 3)

        subject.removeTab(tabs[0].tabUUID)
        XCTAssertEqual(
            subject.normalTabs.count,
            2,
            "normalTabs should reflect the removal after cache invalidation."
        )
    }

    @MainActor
    func testNormalAndPrivateTabs_consistentAfterMutation() {
        // Both computed properties read from the same cached split.
        // They must agree on the total after a mutation.
        var tabs = generateTabs(count: 4)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 2))
        let subject = createSubject(tabs: tabs)

        _ = subject.normalTabs
        _ = subject.privateTabs // Should hit the same cache, does not recompute.

        subject.removeTab(tabs[0].tabUUID) // Invalidates the internal cache.

        let normalTabs = subject.normalTabs
        let privateTabs = subject.privateTabs
        XCTAssertEqual(
            normalTabs.count + privateTabs.count,
            subject.tabs.count,
            "normalTabs and privateTabs must be consistent with each other after mutation."
        )
    }

    @MainActor
    func testNormalAndPrivateTabs_emptyWhenNoTabs() {
        let subject = createSubject()
        XCTAssertTrue(subject.normalTabs.isEmpty)
        XCTAssertTrue(subject.privateTabs.isEmpty)
    }
}
