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
                                createdAtTime: Date()))
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
