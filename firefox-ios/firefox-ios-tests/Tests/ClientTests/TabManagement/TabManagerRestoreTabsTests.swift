// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import Common
@testable import Client

final class TabManagerRestoreTabsTests: TabManagerTestsBase {
    @MainActor
    func testRestoreTabs() {
        // Needed to ensure AppEventQueue is not fired from a previous test case with the same WindowUUID
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 4))

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [mockTabStore] in
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, 4)
                XCTAssertEqual(mockTabStore?.fetchWindowDataCalledCount, 1)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabPresent_withSameURLAsRestoredTab() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        let tabs = generateTabs(count: 1)
        let deeplinkTab = try XCTUnwrap(tabs.first)
        let subject = createSubject(tabs: tabs, windowUUID: testUUID)
        let tabData = getMockTabData(count: 4)
        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: tabData
        )

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                // Tabs count has to be same as restoration data, since deeplink tab has same of URL of a restored tab.
                XCTAssertEqual(subject.tabs.count, tabData.count)
                XCTAssertEqual(subject.selectedTab, deeplinkTab)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabNil_selectsPreviousSelectedTabData() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)

        let tabData = getMockTabData(count: 4)
        let previouslySelectedTabData = try XCTUnwrap(tabData.last)
        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: previouslySelectedTabData.id,
            tabData: tabData
        )

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, tabData.count)
                XCTAssertEqual(subject.selectedTab?.tabUUID, previouslySelectedTabData.id.uuidString)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabNotNil_selectsDeeplinkTab() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        let deeplinkTab = Tab(profile: mockProfile, windowUUID: testUUID)
        let subject = createSubject(tabs: [deeplinkTab], windowUUID: testUUID)

        let tabData = getMockTabData(count: 4)
        let previouslySelectedTabData = try XCTUnwrap(tabData.last)
        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: previouslySelectedTabData.id,
            tabData: tabData
        )

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, tabData.count + 1)
                XCTAssertEqual(subject.selectedTab, deeplinkTab)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabPresent() {
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        setIsDeeplinkOptimizationRefactorEnabled(true)
        // Simulate deeplink tab
        let tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        tab.url = URL(string: "https://example.com")
        let subject = createSubject(tabs: [tab], windowUUID: testUUID)

        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: getMockTabData(count: 4)
        )

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                // Tabs count has to be the sum of deeplink and restored tabs, since the deeplink tab is not present in
                // the restored once.
                XCTAssertEqual(subject.tabs.count, 5)
                expectation.fulfill()
            }
        }

        subject.restoreTabs()
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabPresent_doesnAddDepplinkTabMultipleTimes() throws {
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        setIsDeeplinkOptimizationRefactorEnabled(true)
        // Simulate deeplink tab
        let deeplinkTabData = try XCTUnwrap(getMockTabData(count: 1).first)
        let deeplinkTab = Tab(profile: mockProfile, windowUUID: testUUID)
        deeplinkTab.url = URL(string: deeplinkTabData.siteUrl)
        deeplinkTab.tabUUID = deeplinkTabData.id.uuidString
        let subject = createSubject(tabs: [deeplinkTab], windowUUID: testUUID)

        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: getMockTabData(count: 4)
        )

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                let filteredTabs = subject.tabs.filter {
                    $0.tabUUID == deeplinkTab.tabUUID
                }
                // There has to be only one tab present
                XCTAssertEqual(filteredTabs.count, 1)
                expectation.fulfill()
            }
        }

        subject.restoreTabs()
        wait(for: [expectation])
    }
}
