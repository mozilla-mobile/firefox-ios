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

    // MARK: Saving Data

    func testSaveTabData() async throws {
        let windowData = self.createMockWindow()
        Task {
            let fetchedNonExistingData = await tabDataStore.fetchWindowData(withID: UUID())
            XCTAssertNil(fetchedNonExistingData)
        }
        Task {
            await tabDataStore.saveWindowData(window: windowData)
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
    }

    func testSaveWindowDataWithBackup() async throws {
        let windowData = self.createMockWindow()
        let windowID = windowData.id
        Task {
            await tabDataStore.saveWindowData(window: windowData)
            Task {
                await tabDataStore.saveWindowData(window: windowData)
                let browserKitInfo = BrowserKitInformation.shared
                let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: browserKitInfo.sharedContainerIdentifier)?
                    .appendingPathComponent("profile.backup")
                let baseFilePath = "profile.backup" + "_\(windowID.uuidString)"
                if let backupPath = baseURL?.appendingPathComponent(baseFilePath) {
                    DispatchQueue.main.async {
                        XCTAssertTrue(FileManager.default.fileExists(atPath: backupPath.path))
                    }
                } else {
                    XCTFail("can't create the backup path")
                }
            }
        }
    }

    // MARK: Fetching Data
    func testFetchAllWindowsData() async throws {
        await tabDataStore.clearAllWindowsData()
        let windowData1 = self.createMockWindow()
        let windowData2 = self.createMockWindow()

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
        let windowData = self.createMockWindow()
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

    // MARK: Clearing Data
    func testClearAllTabData() async throws {
        let windowData = self.createMockWindow()
        await tabDataStore.saveWindowData(window: windowData)
        await tabDataStore.clearAllWindowsData()

        let fetchedWindowData = await tabDataStore.fetchAllWindowsData()
        XCTAssertTrue(fetchedWindowData.isEmpty)
    }

    // MARK: Helpers
    func createMockTab() -> TabData {
        return TabData(id: UUID(),
                       title: "Test",
                       siteUrl: "https://test.com",
                       faviconURL: "https://test.com/favicon.ico",
                       isPrivate: false,
                       lastUsedTime: Date(),
                       createdAtTime: Date())
    }

    func createMockWindow() -> WindowData {
        let tab = self.createMockTab()
        return WindowData(id: UUID(),
                          isPrimary: true,
                          activeTabId: tab.id,
                          tabData: [tab])
    }
}
