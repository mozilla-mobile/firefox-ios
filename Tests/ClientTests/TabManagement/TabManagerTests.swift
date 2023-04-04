// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import WebKit
import Shared
@testable import Client

class TabManagerTests: XCTestCase {
    var subject: TabManagerImplementation!
    var mockTabStore: MockTabDataStore!
    var mockProfile: MockProfile!
    var mockDiskImageStore: MockDiskImageStore!
    let webViewConfig: WKWebViewConfiguration = WKWebViewConfiguration()
    let sleepTime: UInt64 = 1_000_000_000
    override func setUp() {
        super.setUp()
        AppConstants.useNewTabDataStore = true
        mockProfile = MockProfile()
        mockDiskImageStore = MockDiskImageStore()
        mockTabStore = MockTabDataStore()
        subject = TabManagerImplementation(profile: mockProfile,
                                           imageStore: mockDiskImageStore,
                                           tabDataStore: mockTabStore)
    }

    override func tearDown() {
        super.tearDown()
        mockProfile = nil
        mockDiskImageStore = nil
        mockTabStore = nil
        subject = nil
    }

    // MARK: - Restore tabs

    func testRestoreTabs() async throws {
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     isPrimary: true,
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 4))
        subject.restoreTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(subject.tabs.count, 4)
    }

    func testRestoreTabsForced() async throws {
        addTabs(count: 5)
        XCTAssertEqual(subject.tabs.count, 5)

        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     isPrimary: true,
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 3))
        subject.restoreTabs(true)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(subject.tabs.count, 3)
    }

    // MARK: - Helper methods

    private func addTabs(count: Int) {
        for _ in 0..<count {
            let tab = Tab(profile: mockProfile, configuration: webViewConfig)
            subject.tabs.append(tab)
        }
    }

    private func getMockTabData(count: Int) -> [TabData] {
        var tabData = [TabData]()
        for _ in 0..<count {
            let tab = TabData(id: UUID(),
                              title: "Firefox",
                              siteUrl: "www.firefox.com",
                              faviconURL: "",
                              isPrivate: false,
                              lastUsedTime: Date(),
                              createdAtTime: Date(),
                              tabGroupData: TabGroupData())
            tabData.append(tab)
        }
        return tabData
    }
}
