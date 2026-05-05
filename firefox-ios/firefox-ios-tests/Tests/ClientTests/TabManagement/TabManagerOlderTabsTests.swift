// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
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
}
