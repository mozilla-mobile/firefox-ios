// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class TabMigrationUtilityTests: XCTestCase {
    var profile: MockProfile!
    var tabDataStore: MockTabDataStore!
    var subject: TabMigrationUtility!
    let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    let selectedTabUUID = UUID(uuidString: "1CEBD34D-44E5-41F8-A686-4EA8C284A5CE")

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        tabDataStore = MockTabDataStore()
        subject = DefaultTabMigrationUtility(profile: profile, tabDataStore: tabDataStore)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        tabDataStore = nil
        subject = nil
    }

    func testShouldRunMigration_OnlyOnce() async {
        XCTAssertTrue(subject.shouldRunMigration)
        _ = await subject.runMigration(savedTabs: [LegacySavedTab]())
        XCTAssertFalse(subject.shouldRunMigration)
    }

    func testRunMigration_SaveDataCalled() async {
        _ = await subject.runMigration(savedTabs: [LegacySavedTab]())
        XCTAssertEqual(tabDataStore.saveWindowDataCalledCount, 1)
    }

    func testRunMigration_SameAmountOfTabs() async {
        let savedTabs = buildSavedTab(amountOfTabs: 3)
        let windowData = await subject.runMigration(savedTabs: savedTabs)
        XCTAssertEqual(windowData.tabData.count, savedTabs.count)
    }

    func testRunMigration_EmptyTabs() async {
        let windowData = await subject.runMigration(savedTabs: [LegacySavedTab]())
        XCTAssertEqual(windowData.tabData.count, 0)
    }

    func testRunMigration_FirstTabAsSelected() async {
        let savedTabs = buildSavedTab(amountOfTabs: 3)
        let windowData = await subject.runMigration(savedTabs: savedTabs)
        XCTAssertEqual(windowData.activeTabId, selectedTabUUID)
    }

    // MARK: - Private
    private func buildSavedTab(amountOfTabs: Int) -> [LegacySavedTab] {
        var savedTabs = [LegacySavedTab]()
        for index in 0..<amountOfTabs {
            // Setup first tab as selected
            let isSelectedTab = index == 0
            let tabUUID = index == 0 ? selectedTabUUID : UUID()

            let saveTab = LegacySavedTab(screenshotUUID: tabUUID,
                                         isSelected: isSelectedTab,
                                         title: "",
                                         isPrivate: false,
                                         faviconURL: nil,
                                         url: URL(string: "https://test.com"),
                                         sessionData: nil,
                                         uuid: UUID().uuidString,
                                         tabGroupData: nil,
                                         createdAt: Date().toTimestamp(),
                                         hasHomeScreenshot: false)
            savedTabs.append(saveTab)
        }

        return savedTabs
    }
}
