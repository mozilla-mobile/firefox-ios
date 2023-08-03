// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import TabDataStore
import Common

final class TabDataStoreTests: XCTestCase {
    private var tabDataStore: DefaultTabDataStore!
    private var mockFileManager: TabFileManagerMock!
    private let sleepTime: UInt64 = 1 * NSEC_PER_SEC

    override func setUp() {
        super.setUp()
        mockFileManager = TabFileManagerMock()
        tabDataStore = DefaultTabDataStore(fileManager: mockFileManager,
                                           throttleTime: 100)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Saving Data

    func testSaveWindowData() async throws {
        let windowData = self.createMockWindow()
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")
        mockFileManager.pathContents = []
        mockFileManager.windowData = windowData
        mockFileManager.fileExists = false

        await tabDataStore.saveWindowData(window: windowData, forced: false)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 2)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 2)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 1)
        XCTAssertEqual(mockFileManager.copyItemCalledCount, 0)
        XCTAssertEqual(mockFileManager.writeWindowDataCalledCount, 1)
    }

    func testSaveWindowDataWithBackup() async throws {
        let windowData = self.createMockWindow()
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory1")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory2")
        mockFileManager.pathContents = []
        mockFileManager.windowData = windowData
        mockFileManager.fileExists = true

        await tabDataStore.saveWindowData(window: windowData, forced: false)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 4)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 3)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 0)
        XCTAssertEqual(mockFileManager.copyItemCalledCount, 1)
        XCTAssertEqual(mockFileManager.writeWindowDataCalledCount, 1)
    }

    // MARK: - Fetching Data

    func testFetchWindowData() async throws {
        let windowData = self.createMockWindow()
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")
        mockFileManager.pathContents = [URL(string: "some/directory")!]
        mockFileManager.windowData = windowData
        let fetchedWindowData = await tabDataStore.fetchWindowData()
        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 1)
        XCTAssertEqual(mockFileManager.contentsOfDirectoryCalledCount, 1)
        XCTAssertEqual(mockFileManager.getWindowDataFromPathCalledCount, 1)
        XCTAssertEqual(fetchedWindowData?.id, windowData.id)
    }

    // MARK: - Clearing Data

    func testClearAllTabData() async throws {
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory1")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory2")
        await tabDataStore.clearAllWindowsData()
        XCTAssertEqual(mockFileManager.removeAllFilesAtCalledCount, 2)
    }

    // MARK: - Helpers

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
