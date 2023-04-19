// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import TabDataStore
import Common

final class TabDataStoreTests: XCTestCase {
    private var tabDataStore: DefaultTabDataStore!

    override func setUp() {
        super.setUp()
        tabDataStore = DefaultTabDataStore()
        BrowserKitInformation.shared.configure(buildChannel: .other,
                                               nightlyAppVersion: "",
                                               sharedContainerIdentifier: "group.org.mozilla.ios.Fennec")
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSaveTabData() async throws {
        let tab = TabData(id: UUID(),
                          title: "Test",
                          siteUrl: "https://test.com",
                          faviconURL: "https://test.com/favicon.ico",
                          isPrivate: false,
                          lastUsedTime: Date(),
                          createdAtTime: Date())
        let windowData = WindowData(id: UUID(),
                                    isPrimary: true,
                                    activeTabId: tab.id,
                                    tabData: [tab])

        Task {
            let fetchedNonExistingData = await tabDataStore.fetchWindowData(withID: UUID())
            XCTAssertNil(fetchedNonExistingData)
        }
        Task {
            await tabDataStore.saveWindowData(window: windowData)
        }

        Task {
            let fetchedWindowData = await tabDataStore.fetchWindowData(withID: windowData.id)
            DispatchQueue.main.async {
                XCTAssertEqual(fetchedWindowData?.id, windowData.id)
                XCTAssertEqual(fetchedWindowData?.isPrimary, windowData.isPrimary)
                XCTAssertEqual(fetchedWindowData?.activeTabId, windowData.activeTabId)
                XCTAssertEqual(fetchedWindowData?.tabData.count, windowData.tabData.count)
            }
        }
    }

    func testFetchAllWindowsData() async throws {
        await tabDataStore.clearAllWindowsData()
        let tab1 = TabData(id: UUID(),
                           title: "Test1",
                           siteUrl: "https://test1.com",
                           faviconURL: "https://test1.com/favicon.ico",
                           isPrivate: true,
                           lastUsedTime: Date(),
                           createdAtTime: Date())

        let tab2 = TabData(id: UUID(),
                           title: "Test2",
                           siteUrl: "https://test2.com",
                           faviconURL: "https://test2.com/favicon.ico",
                           isPrivate: false,
                           lastUsedTime: Date(),
                           createdAtTime: Date())

        let windowData1 = WindowData(id: UUID(),
                                     isPrimary: true,
                                     activeTabId: tab1.id,
                                     tabData: [tab1])

        let windowData2 = WindowData(id: UUID(),
                                     isPrimary: false,
                                     activeTabId: tab2.id,
                                     tabData: [tab2])

        // Save the WindowData objects
        Task {
            await tabDataStore.saveWindowData(window: windowData1)
        }
        Task {
            await tabDataStore.saveWindowData(window: windowData2)
            Task {
                // Fetch all WindowData objects
                let fetchedWindowsData = await tabDataStore.fetchAllWindowsData()
                // Verify the fetched data
                XCTAssertEqual(fetchedWindowsData.count, 2)
                XCTAssertTrue(fetchedWindowsData.contains(where: { $0.id == windowData1.id }))
                XCTAssertTrue(fetchedWindowsData.contains(where: { $0.id == windowData2.id }))
            }
        }
    }

    func testFetchWindowDataWithId() async throws {
        // Create a sample TabData and WindowData object
        let tab = TabData(id: UUID(),
                          title: "Test",
                          siteUrl: "https://test.com",
                          faviconURL: "https://test.com/favicon.ico",
                          isPrivate: false,
                          lastUsedTime: Date(),
                          createdAtTime: Date())

        let windowData = WindowData(id: UUID(),
                                    isPrimary: true,
                                    activeTabId: tab.id,
                                    tabData: [tab])
        // Save the WindowData object
        Task {
            await tabDataStore.saveWindowData(window: windowData)
            // Fetch the WindowData object using its ID
            Task {
                let fetchedWindowData = await tabDataStore.fetchWindowData(withID: windowData.id)

                // Verify the fetched data
                XCTAssertNotNil(fetchedWindowData)
                XCTAssertEqual(fetchedWindowData?.id, windowData.id)
                XCTAssertEqual(fetchedWindowData?.isPrimary, windowData.isPrimary)
                XCTAssertEqual(fetchedWindowData?.activeTabId, windowData.activeTabId)
                XCTAssertEqual(fetchedWindowData?.tabData.count, windowData.tabData.count)
            }
        }
    }

    func testClearAllTabData() async throws {
        let tab = TabData(id: UUID(),
                          title: "Test",
                          siteUrl: "https://test.com",
                          faviconURL: "https://test.com/favicon.ico",
                          isPrivate: false,
                          lastUsedTime: Date(),
                          createdAtTime: Date())

        let windowData = WindowData(id: UUID(),
                                    isPrimary: true,
                                    activeTabId: tab.id,
                                    tabData: [tab])

        await tabDataStore.saveWindowData(window: windowData)
        await tabDataStore.clearAllWindowsData()

        let fetchedWindowData = await tabDataStore.fetchAllWindowsData()

        // Assuming the default fetchTabData() returns an empty WindowData object
        XCTAssertTrue(fetchedWindowData.isEmpty)
    }
}
