// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import TabDataStore
import Common

final class TabDataStoreTests: XCTestCase {
    private var mockFileManager: TabFileManagerMock!
    private let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    private let defaultTestTabWindowUUID = UUID(uuidString: "E3FF60DA-D1E7-407B-AA3B-130D48B3909D")!

    override func setUp() {
        super.setUp()
        mockFileManager = TabFileManagerMock()
    }

    override func tearDown() {
        super.tearDown()
        mockFileManager = nil
    }

    // MARK: - Saving Data

    func testSaveWindowData_noWindowDataDirectory_returns() async throws {
        let windowData = createMockWindow(uuid: defaultTestTabWindowUUID)
        let subject = createSubject()

        await subject.saveWindowData(window: windowData, forced: false)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 0)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 0)
        XCTAssertEqual(mockFileManager.copyItemCalledCount, 0)
        XCTAssertEqual(mockFileManager.writeWindowDataCalledCount, 0)
    }

    func testSaveWindowData_createsDirectory_notForced() async throws {
        let subject = createSubject()
        let windowData = createMockWindow(uuid: defaultTestTabWindowUUID)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")
        mockFileManager.pathContents = []
        mockFileManager.windowData = windowData
        mockFileManager.fileExists = false

        await subject.saveWindowData(window: windowData, forced: false)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 2)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 2)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 1)
        XCTAssertEqual(mockFileManager.copyItemCalledCount, 0)
        XCTAssertEqual(mockFileManager.writeWindowDataCalledCount, 1)
    }

    func testSaveWindowDataWithBackup_doesntCreateDirectory_notForced() async throws {
        let subject = createSubject()
        let windowData = createMockWindow(uuid: defaultTestTabWindowUUID)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory1")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory2")
        mockFileManager.pathContents = []
        mockFileManager.windowData = windowData
        mockFileManager.fileExists = true

        await subject.saveWindowData(window: windowData, forced: false)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 4)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 3)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 0)
        XCTAssertEqual(mockFileManager.copyItemCalledCount, 1)
        XCTAssertEqual(mockFileManager.writeWindowDataCalledCount, 1)
    }

    func testSaveWindowDataForceAndNotForcedMix() async throws {
        let subject = createSubject()
        let windowData = createMockWindow(uuid: defaultTestTabWindowUUID)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory1")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory2")
        mockFileManager.pathContents = []
        mockFileManager.windowData = windowData
        mockFileManager.fileExists = true

        await subject.saveWindowData(window: windowData, forced: false)
        await subject.saveWindowData(window: windowData, forced: false)
        await subject.saveWindowData(window: windowData, forced: true)
        try await Task.sleep(nanoseconds: 3 * sleepTime)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 8)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 5)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 0)
        XCTAssertEqual(mockFileManager.copyItemCalledCount, 1)
        XCTAssertEqual(mockFileManager.writeWindowDataCalledCount, 2)
    }

    // MARK: - Fetching Data

    func testFetchWindowData_withoutDirectory_returnEmpty() async throws {
        let subject = createSubject()

        let fetchedWindowData = await subject.fetchWindowData(uuid: defaultTestTabWindowUUID)

        // We expect two calls to windowDataDirectory since fetchWindowData
        // will check first for the primary WindowData (for a given UUID)
        // and then also check the backup URL location.
        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 2)
        XCTAssertEqual(mockFileManager.getWindowDataFromPathCalledCount, 0)
        XCTAssertNil(fetchedWindowData)
    }

    func testFetchWindowData_withoutWindowDataAndBackupURL_returnEmpty() async throws {
        let subject = createSubject()
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")

        let fetchedWindowData = await subject.fetchWindowData(uuid: defaultTestTabWindowUUID)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 2)
        XCTAssertEqual(mockFileManager.getWindowDataFromPathCalledCount, 0)
        XCTAssertNil(fetchedWindowData)
    }

    func testFetchWindowData_withoutWindowDataEmptyData_useBackupReturnEmpty() async throws {
        let subject = createSubject()
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory")

        let fetchedWindowData = await subject.fetchWindowData(uuid: defaultTestTabWindowUUID)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 2)
        XCTAssertEqual(mockFileManager.getWindowDataFromPathCalledCount, 0)
        XCTAssertNil(fetchedWindowData)
    }

    func testFetchWindowData_withWindowData_returnFetchedWindow() async throws {
        let subject = createSubject()
        let windowData = createMockWindow(uuid: defaultTestTabWindowUUID)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")
        mockFileManager.pathContents = [URL(string: "some/directory")!]
        mockFileManager.fileExists = true
        mockFileManager.windowData = windowData

        let fetchedWindowData = await subject.fetchWindowData(uuid: defaultTestTabWindowUUID)

        XCTAssertEqual(mockFileManager.windowDataDirectoryCalledCount, 1)
        XCTAssertEqual(mockFileManager.contentsOfDirectoryCalledCount, 0)
        XCTAssertEqual(mockFileManager.getWindowDataFromPathCalledCount, 1)
        XCTAssertEqual(fetchedWindowData?.id, windowData.id)
    }

    // MARK: - Fetching and Saving Data

    func testPreserveBeforeRestore() async throws {
        let subject = createSubject()
        let windowData = createMockWindow(uuid: defaultTestTabWindowUUID)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory1")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory2")
        mockFileManager.pathContents = [URL(string: "some/directory")!]
        mockFileManager.fileExists = true

        await subject.saveWindowData(window: windowData, forced: false) // preserve
        try await Task.sleep(nanoseconds: sleepTime)
        let fetchedWindowData = await subject.fetchWindowData(uuid: defaultTestTabWindowUUID) // restore
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(fetchedWindowData?.id, windowData.id)
        XCTAssertEqual(fetchedWindowData?.tabData.count, windowData.tabData.count)
    }

    func testRestoreBeforePreserve() async throws {
        let subject = createSubject()
        let windowData = createMockWindow(uuid: defaultTestTabWindowUUID)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory1")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory2")
        mockFileManager.pathContents = [URL(string: "some/directory")!]
        mockFileManager.fileExists = true

        let fetchedWindowData = await subject.fetchWindowData(uuid: defaultTestTabWindowUUID) // restore
        await subject.saveWindowData(window: windowData, forced: false) // preserve
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertNil(fetchedWindowData)
    }

    func testSavingTwiceReturnsMostRecentData() async throws {
        let subject = createSubject()
        let windowData1 = createMockWindow(uuid: defaultTestTabWindowUUID)
        let windowData2 = createMockWindow(uuid: UUID(uuidString: "ABFF60DA-D1E7-407B-AA3B-130D48B31012")!)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory1")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory2")
        mockFileManager.pathContents = [URL(string: "some/directory")!]
        mockFileManager.fileExists = true

        await subject.saveWindowData(window: windowData1, forced: false) // preserve
        await subject.saveWindowData(window: windowData2, forced: false) // preserve
        try await Task.sleep(nanoseconds: sleepTime)

        let fetchedWindowData = await subject.fetchWindowData(uuid: defaultTestTabWindowUUID) // restore
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(fetchedWindowData?.id, windowData2.id)
        XCTAssertEqual(fetchedWindowData?.tabData.count, windowData2.tabData.count)
    }

    // MARK: - Clearing Data

    func testClearAllTabData() async throws {
        let subject = createSubject()
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory1")
        mockFileManager.backupDirectoryURL = URL(string: "some/directory2")
        await subject.clearAllWindowsData()
        XCTAssertEqual(mockFileManager.removeAllFilesAtCalledCount, 2)
    }

    // MARK: - Helpers

    func createSubject(throttleTime: UInt64 = 100) -> TabDataStore {
        let subject = DefaultTabDataStore(fileManager: mockFileManager,
                                          throttleTime: 100)
        trackForMemoryLeaks(subject)
        return subject
    }

    func createMockTabs() -> [TabData] {
        var tabs = [TabData]()
        for index in 0..<100 {
            tabs.append(TabData(id: UUID(),
                                title: "Test \(index)",
                                siteUrl: "https://test.com",
                                faviconURL: "https://test.com/favicon.ico",
                                isPrivate: false,
                                lastUsedTime: Date(),
                                createdAtTime: Date()))
        }
        return tabs
    }

    func createMockWindow(uuid: UUID) -> WindowData {
        let tabs = createMockTabs()
        return WindowData(id: uuid,
                          activeTabId: tabs[0].id,
                          tabData: tabs)
    }
}
