// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import TabDataStore
import Common

final class TabDataStoreTests: XCTestCase {
    private var tabDataStore: DefaultTabDataStore!
    private var mockFileManger: TabFileManagerMock!
    private let sleepTime: UInt64 = 1 * NSEC_PER_SEC

    override func setUp() {
        super.setUp()
        mockFileManger = TabFileManagerMock()
        tabDataStore = DefaultTabDataStore(fileManager: mockFileManger,
                                           throttleTime: 100)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Saving Data

    func testSaveTabData() async throws {
        await tabDataStore.clearAllWindowsData()
        let windowData = self.createMockWindow()
        await tabDataStore.saveWindowData(window: windowData)
        try await Task.sleep(nanoseconds: sleepTime)
        let fetchedWindowData = await tabDataStore.fetchWindowData()
        XCTAssertEqual(fetchedWindowData?.id, windowData.id)
        XCTAssertEqual(fetchedWindowData?.isPrimary, windowData.isPrimary)
        XCTAssertEqual(fetchedWindowData?.activeTabId, windowData.activeTabId)
        XCTAssertEqual(fetchedWindowData?.tabData.count, windowData.tabData.count)
    }

    func testSaveWindowDataWithBackup() async throws {
        let windowData = self.createMockWindow()
        let windowID = windowData.id
        await tabDataStore.saveWindowData(window: windowData)
        try await Task.sleep(nanoseconds: sleepTime)
        await tabDataStore.saveWindowData(window: windowData)
        try await Task.sleep(nanoseconds: sleepTime)
        let baseURL = mockFileManger.windowDataDirectory(isBackup: true)
        let baseFilePath = "window" + "-\(windowID.uuidString)"
        if let backupPath = baseURL?.appendingPathComponent(baseFilePath) {
            XCTAssertTrue(mockFileManger.fileExists(atPath: backupPath))
        } else {
            XCTFail("can't create the backup path")
        }
    }

    // MARK: Fetching Data
    func testFetchBackup() async throws {
        let windowData = self.createMockWindow()
        let windowID = windowData.id
        await tabDataStore.saveWindowData(window: windowData)
        try await Task.sleep(nanoseconds: sleepTime)
        await tabDataStore.saveWindowData(window: windowData)
        try await Task.sleep(nanoseconds: sleepTime)
        let baseURL = mockFileManger.windowDataDirectory(isBackup: true)
        let baseFilePath = "window" + "-\(windowID.uuidString)"
        if let backupPath = baseURL?.appendingPathComponent(baseFilePath) {
            XCTAssertTrue(mockFileManger.fileExists(atPath: backupPath))
            do {
                let data = try Data(contentsOf: backupPath)
                let backupWindowData = try JSONDecoder().decode(WindowData.self, from: data)
                XCTAssertEqual(backupWindowData.id, windowData.id)
            } catch {
                XCTFail("can't read the backup")
            }
        } else {
            XCTFail("can't create the backup path")
        }
    }

    // MARK: Clearing Data
    func testClearAllTabData() async throws {
        let windowData = self.createMockWindow()
        await tabDataStore.saveWindowData(window: windowData)
        try await Task.sleep(nanoseconds: sleepTime)
        await tabDataStore.clearAllWindowsData()
        let fetchedWindowData = await tabDataStore.fetchWindowData()
        XCTAssertNil(fetchedWindowData)
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
        return WindowData(id: UUID(uuidString: "E3FF60DA-D1E7-407B-AA3B-130D48B3909D")!,
                          isPrimary: true,
                          activeTabId: tab.id,
                          tabData: [tab])
    }
}
