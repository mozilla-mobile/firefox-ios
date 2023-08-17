// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import TabDataStore

final class TabSessionStoreTests: XCTestCase {
    var mockFileManager: TabFileManagerMock!

    override func setUp() {
        super.setUp()
        mockFileManager = TabFileManagerMock()
    }

    override func tearDown() {
        super.tearDown()
        mockFileManager = nil
    }

    // MARK: Save

    func testSaveWithoutDirectory() async {
        let subject = createSubject()
        let uuid = UUID()
        let dataFile = Data(count: 100)
        await subject.saveTabSession(tabID: uuid, sessionData: dataFile)

        XCTAssertEqual(mockFileManager.tabSessionDataDirectoryCalledCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 0)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 0)
    }

    func testSaveTabSession() async {
        let subject = createSubject()
        let uuid = UUID()
        let dataFile = Data(count: 100)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")
        mockFileManager.fileExists = false
        await subject.saveTabSession(tabID: uuid, sessionData: dataFile)

        XCTAssertEqual(mockFileManager.tabSessionDataDirectoryCalledCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 1)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 1)
    }

    // MARK: Fetch

    func testFetchTabSessionWithoutDirectory() async {
        let subject = createSubject()
        let uuid = UUID()

        _ = await subject.fetchTabSession(tabID: uuid)

        XCTAssertEqual(mockFileManager.tabSessionDataDirectoryCalledCount, 1)
    }

    func testFetchTabSession() async {
        let subject = createSubject()
        let uuid = UUID()
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")

        _ = await subject.fetchTabSession(tabID: uuid)

        XCTAssertEqual(mockFileManager.tabSessionDataDirectoryCalledCount, 1)
    }

    // MARK: Helper functions

    func createSubject() -> DefaultTabSessionStore {
        let subject = DefaultTabSessionStore(fileManager: mockFileManager)
        trackForMemoryLeaks(subject)
        return subject
    }
}
