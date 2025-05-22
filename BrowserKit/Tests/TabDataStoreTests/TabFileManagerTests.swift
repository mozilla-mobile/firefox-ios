// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import TabDataStore
import Common

final class TabFileManagerTests: XCTestCase {
    private let defaultTestTabWindowUUID = UUID(uuidString: "E3FF60DA-D1E7-407B-AA3B-130D48B3909D")!
    override func setUp() {
        super.setUp()
        BrowserKitInformation.shared.configure(buildChannel: .developer,
                                               nightlyAppVersion: "0",
                                               sharedContainerIdentifier: "id")
    }

    func testWriteWindowDataThenRetrieve() throws {
        let subject = DefaultTabFileManager()
        let windowData = createMockWindow()
        let windowDataDirectory = subject.windowDataDirectory(isBackup: false)!
        subject.createDirectoryAtPath(path: windowDataDirectory)

        let windowURL = windowDataDirectory.appendingPathComponent("window-\(windowData.id.uuidString)")
        try subject.writeWindowData(windowData: windowData, to: windowURL)
        let fetchedWindowData = try subject.getWindowDataFromPath(path: windowURL)

        XCTAssertNotNil(fetchedWindowData)
        XCTAssertEqual(fetchedWindowData?.id, windowData.id)
    }

    func testSessionData() throws {
        let tabID = UUID()
        let sessionData = Data(count: 100)
        let subject = DefaultTabFileManager()
        let sessionDataDirectory = subject.tabSessionDataDirectory()!
        subject.createDirectoryAtPath(path: sessionDataDirectory)

        let sessionURL = sessionDataDirectory.appendingPathComponent("tab-\(tabID.uuidString)")
        try sessionData.write(to: sessionURL, options: .atomicWrite)
        let retrievedSessionData = try Data(contentsOf: sessionURL)

        XCTAssertNotNil(retrievedSessionData)
        XCTAssertEqual(retrievedSessionData, sessionData)
    }

    // MARK: - Legacy tab group data checks
    // Tab group data was removed as part of FXIOS-11987, but we still want to properly decode TabData() that
    // include `tabGroupData`.

    func testGetWindowDataFromPath_withLegacyTabDataIncludingTabGroupData_succeeds() throws {
        let now = Date()
        let timestamp = now.timeIntervalSince1970

        let legacyTabJSON = """
    {
        "id": "\(UUID())",
        "title": "Legacy Tab",
        "siteUrl": "https://example.com",
        "faviconURL": null,
        "isPrivate": false,
        "lastUsedTime": \(timestamp),
        "createdAtTime": \(timestamp),
        "tabGroupData": {
            "searchTerm": "firefox",
            "searchUrl": "https://search.com?q=firefox",
            "nextUrl": "https://mozilla.org",
            "tabHistoryCurrentState": "newTab"
        }
    }
    """

        let windowID = defaultTestTabWindowUUID
        let activeTabID = UUID()
        let windowJSON = """
    {
        "id": "\(windowID)",
        "activeTabId": "\(activeTabID)",
        "tabData": [\(legacyTabJSON)]
    }
    """.data(using: .utf8)!

        // Create manager and path
        let subject = DefaultTabFileManager()
        let windowDataDirectory = subject.windowDataDirectory(isBackup: false)!
        subject.createDirectoryAtPath(path: windowDataDirectory)

        let windowPath = windowDataDirectory.appendingPathComponent("window-\(windowID.uuidString)")
        try windowJSON.write(to: windowPath, options: .atomicWrite)

        // Try to decode legacy data through real decoding pipeline
        let result = try subject.getWindowDataFromPath(path: windowPath)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, windowID)
        XCTAssertEqual(result?.tabData.count, 1)
        XCTAssertEqual(result?.tabData.first?.title, "Legacy Tab")
    }

    func testGetWindowDataFromPath_withLegacyTabDataIncludingNullTabGroupData_succeeds() throws {
        let now = Date()
        let timestamp = now.timeIntervalSince1970

        let legacyTabJSON = """
    {
        "id": "\(UUID())",
        "title": "Legacy Tab",
        "siteUrl": "https://example.com",
        "faviconURL": null,
        "isPrivate": false,
        "lastUsedTime": \(timestamp),
        "createdAtTime": \(timestamp),
        "tabGroupData": null
    }
    """

        let windowID = defaultTestTabWindowUUID
        let activeTabID = UUID()
        let windowJSON = """
    {
        "id": "\(windowID)",
        "activeTabId": "\(activeTabID)",
        "tabData": [\(legacyTabJSON)]
    }
    """.data(using: .utf8)!

        // Create manager and path
        let subject = DefaultTabFileManager()
        let windowDataDirectory = subject.windowDataDirectory(isBackup: false)!
        subject.createDirectoryAtPath(path: windowDataDirectory)

        let windowPath = windowDataDirectory.appendingPathComponent("window-\(windowID.uuidString)")
        try windowJSON.write(to: windowPath, options: .atomicWrite)

        // Try to decode legacy data through real decoding pipeline
        let result = try subject.getWindowDataFromPath(path: windowPath)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, windowID)
        XCTAssertEqual(result?.tabData.count, 1)
        XCTAssertEqual(result?.tabData.first?.title, "Legacy Tab")
    }

    // MARK: Helper functions

    func createMockTabs() -> [TabData] {
        var tabs = [TabData]()
        for index in 0..<100 {
            tabs.append(TabData(id: UUID(),
                                title: "Test \(index)",
                                siteUrl: "https://test.com",
                                faviconURL: "https://test.com/favicon.ico",
                                isPrivate: false,
                                lastUsedTime: Date(),
                                createdAtTime: Date(),
                                temporaryDocumentSession: [:]))
        }
        return tabs
    }

    func createMockWindow() -> WindowData {
        let tabs = createMockTabs()
        return WindowData(id: defaultTestTabWindowUUID,
                          activeTabId: tabs[0].id,
                          tabData: tabs)
    }
}
