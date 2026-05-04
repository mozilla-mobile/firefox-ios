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

// Note: Some tests are annotated with @MainActor because a new Tab is created without the zombie flag set to true.
// This is unavoidable with the current architecture given a new tab is created as a side effect. For these tabs, if
// the test isn't run on the main thread, then in its deinit the webView.navigationDelegate is updated not on the
// main thread, causing failures in Bitrise. This should be improved. [FXIOS-10110]
class TabManagerTestsBase: XCTestCase {
    var tabWindowUUID: WindowUUID!
    var mockTabStore: MockTabDataStore!
    var mockSessionStore: MockTabSessionStore!
    var mockProfile: MockProfile!
    var mockDiskImageStore: MockDiskImageStore!
    let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    /// 9 Sep 2001 8:00 pm GMT + 0
    let testDate = Date(timeIntervalSince1970: 1_000_065_600)

    override func setUp() async throws {
        try await super.setUp()

        // For this test suite, use a consistent window UUID for all test cases
        let uuid: WindowUUID = .XCTestDefaultUUID
        tabWindowUUID = uuid

        mockProfile = MockProfile()
        await DependencyHelperMock().bootstrapDependencies(injectedProfile: mockProfile)
        mockDiskImageStore = MockDiskImageStore()
        mockTabStore = MockTabDataStore()
        mockSessionStore = MockTabSessionStore()
        setIsDeeplinkOptimizationRefactorEnabled(false)
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockDiskImageStore = nil
        mockTabStore = nil
        mockSessionStore = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Helpers

    @MainActor
    func createSubject(tabs: [Tab] = [],
                       windowUUID: WindowUUID? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line) -> TabManagerImplementation {
        let subject = TabManagerImplementation(
            profile: mockProfile,
            imageStore: mockDiskImageStore,
            uuid: ReservedWindowUUID(uuid: windowUUID ?? tabWindowUUID, isNew: false),
            tabDataStore: mockTabStore,
            tabSessionStore: mockSessionStore,
            tabs: tabs
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    func setIsDeeplinkOptimizationRefactorEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.deeplinkOptimizationRefactorFeature.with { _, _ in
            return DeeplinkOptimizationRefactorFeature(enabled: enabled)
        }
    }

    func setupNimbusTabTrayUIExperimentTesting(isEnabled: Bool) {
        FxNimbus.shared.features.tabTrayUiExperiments.with { _, _ in
            return TabTrayUiExperiments(enabled: isEnabled)
        }
    }

    enum TabType {
        case normal
        case normalOlderLastMonth
        case normalOlder2Weeks
        case normalOlderYesterday
        case privateAny // `private` alone is a reserved compiler keyword
    }

    @MainActor
    func generateTabs(ofType type: TabType = .normal, count: Int) -> [Tab] {
        var tabs = [Tab]()
        for i in 0..<count {
            let tab: Tab
            switch type {
            case .normal:
                tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
            case .normalOlderLastMonth:
                let lastMonthDate = testDate.lastMonth
                tab = Tab(profile: MockProfile(), windowUUID: tabWindowUUID, tabCreatedTime: lastMonthDate)
            case .privateAny:
                tab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID)
            case .normalOlder2Weeks:
                let twoWeeksDate = testDate.lastTwoWeek
                tab = Tab(profile: MockProfile(), windowUUID: tabWindowUUID, tabCreatedTime: twoWeeksDate)
            case .normalOlderYesterday:
                let yesterdayDate = testDate.dayBefore
                tab = Tab(profile: MockProfile(), windowUUID: tabWindowUUID, tabCreatedTime: yesterdayDate)
            }
            tab.url = testURL(count: i)
            tabs.append(tab)
        }
        return tabs
    }

    func getMockTabData(count: Int) -> [TabData] {
        var tabData = [TabData]()
        for i in 0..<count {
            let tab = TabData(id: UUID(),
                              title: "Firefox",
                              siteUrl: testURL(count: i).absoluteString,
                              faviconURL: "",
                              isPrivate: false,
                              lastUsedTime: Date(),
                              createdAtTime: Date(),
                              temporaryDocumentSession: [:])
            tabData.append(tab)
        }
        return tabData
    }

    /// Generate a test URL given a count that is used as query parameter to get diversified URLs
    func testURL(count: Int) -> URL {
        return URL(string: "https://mozilla.com?item=\(count)")!
    }

    @MainActor
    func setupForFindRightOrLeftTab_mixedTypes(file: StaticString = #filePath,
                                               line: UInt = #line) -> TabManagerImplementation {
        // Set up a tab array as follows:
        // [N1, P1, P2, P3, N2, N3, N4, N5, P3]
        //   0   1   2   3   4   5   6   7   8
        let tabs1 = generateTabs(ofType: .normal, count: 1)
        let tabs2 = generateTabs(ofType: .privateAny, count: 3)
        let tabs3to5 = generateTabs(ofType: .normalOlderLastMonth, count: 2)
        let tabs6to7 = generateTabs(ofType: .normal, count: 2)
        let tabs8 = generateTabs(ofType: .privateAny, count: 1)

        let tabManager = createSubject(tabs: tabs1 + tabs2 + tabs3to5 + tabs6to7 + tabs8)
        XCTAssertEqual(tabManager.tabs.count, 9, file: file, line: line)
        XCTAssertEqual(tabManager.normalTabs.count, 5, file: file, line: line)
        XCTAssertEqual(tabManager.privateTabs.count, 4, file: file, line: line)
        return tabManager
    }
}
