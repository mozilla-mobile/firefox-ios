// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

class TabMigrationUtilityTests: XCTestCase {
    var profile: MockProfile!
    var tabDataStore: MockTabDataStore!
    let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    let selectedTabUUID = UUID(uuidString: "1CEBD34D-44E5-41F8-A686-4EA8C284A5CE")
    private var tabDataWindowUUID: WindowUUID!

    override func setUp() {
        super.setUp()
        tabDataWindowUUID = WindowUUID.XCTestDefaultUUID
        profile = MockProfile()
        tabDataStore = MockTabDataStore()
    }

    override func tearDown() {
        profile = nil
        tabDataStore = nil
        super.tearDown()
    }

    func testShouldRunMigration_OnlyOnce() async {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldRunMigration)
        _ = await subject.runMigration(for: tabDataWindowUUID)
        XCTAssertFalse(subject.shouldRunMigration)
    }

    func testRunMigration_SaveDataCalled() async {
        let subject = createSubject()
        _ = await subject.runMigration(for: tabDataWindowUUID)
        XCTAssertEqual(tabDataStore.saveWindowDataCalledCount, 1)
    }

    func testRunMigration_SameAmountOfTabs() async {
        var subject = createSubject()
        subject.legacyTabs = buildSavedTab(amountOfTabs: 3)
        let windowData = await subject.runMigration(for: tabDataWindowUUID)
        XCTAssertEqual(windowData.tabData.count, subject.legacyTabs.count)
    }

    func testRunMigration_EmptyTabs() async {
        let subject = createSubject()
        let windowData = await subject.runMigration(for: tabDataWindowUUID)
        XCTAssertEqual(windowData.tabData.count, 0)
    }

    func testRunMigration_FirstTabAsSelected() async {
        var subject = createSubject()
        subject.legacyTabs = buildSavedTab(amountOfTabs: 3)
        let windowData = await subject.runMigration(for: tabDataWindowUUID)
        XCTAssertEqual(windowData.activeTabId, selectedTabUUID)
    }

    func testRunMigration_AllTabDataIsMigrated() async {
        var subject = createSubject()
        subject.legacyTabs = buildSavedTab(amountOfTabs: 1)
        let windowData = await subject.runMigration(for: tabDataWindowUUID)

        let migratedTab = windowData.tabData[0]
        XCTAssertEqual(migratedTab.id, selectedTabUUID)
        XCTAssertEqual(migratedTab.title, "Title 0")
        XCTAssertEqual(migratedTab.siteUrl, "https://test.com")
        XCTAssertEqual(migratedTab.faviconURL, "https://test.com")
        XCTAssertEqual(migratedTab.isPrivate, false)
        XCTAssertEqual(migratedTab.tabGroupData?.searchTerm, "searchTerm")
        XCTAssertEqual(migratedTab.tabGroupData?.searchUrl, "searchUrl")
        XCTAssertEqual(migratedTab.tabGroupData?.nextUrl, "nextReferralUrl")
    }

    // MARK: - Helper functions
    private func buildSavedTab(amountOfTabs: Int) -> [LegacySavedTab] {
        var savedTabs = [LegacySavedTab]()
        for index in 0..<amountOfTabs {
            // Setup first tab as selected
            let isSelectedTab = index == 0
            let tabUUID = index == 0 ? selectedTabUUID : UUID()

            let tabGroupData = LegacyTabGroupData(searchTerm: "searchTerm",
                                                  searchUrl: "searchUrl",
                                                  nextReferralUrl: "nextReferralUrl")

            let saveTab = LegacySavedTab(screenshotUUID: tabUUID,
                                         isSelected: isSelectedTab,
                                         title: "Title \(index)",
                                         isPrivate: false,
                                         faviconURL: "https://test.com",
                                         url: URL(string: "https://test.com"),
                                         uuid: UUID().uuidString,
                                         tabGroupData: tabGroupData,
                                         createdAt: Date().toTimestamp(),
                                         hasHomeScreenshot: false)
            savedTabs.append(saveTab)
        }

        return savedTabs
    }

    private func createSubject() -> TabMigrationUtility {
        let subject = DefaultTabMigrationUtility(profile: profile, tabDataStore: tabDataStore)
        trackForMemoryLeaks(subject)
        return subject
    }
}
