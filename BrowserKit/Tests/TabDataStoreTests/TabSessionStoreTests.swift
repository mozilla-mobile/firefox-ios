// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import TabDataStore

final class TabSessionStoreTests: XCTestCase {
    var mockFileManager = TabFileManagerMock()
    var subject = DefaultTabSessionStore()

    override func setUp() {
        super.setUp()
        mockFileManager = TabFileManagerMock()
        subject = DefaultTabSessionStore(fileManager: mockFileManager)
    }

    func testSaveTabSession() async {
        let uuid = UUID()
        let dataFile = Data(count: 100)
        mockFileManager.primaryDirectoryURL = URL(string: "some/directory")
        mockFileManager.fileExists = false
        await subject.saveTabSession(tabID: uuid, sessionData: dataFile)

        XCTAssertEqual(mockFileManager.tabSessionDataDirectoryCalledCount, 1)
        XCTAssertEqual(mockFileManager.fileExistsCalledCount, 1)
        XCTAssertEqual(mockFileManager.createDirectoryAtPathCalledCount, 1)
    }

    func testFetchTabSession() async {
        let uuid = UUID()

        _ = await subject.fetchTabSession(tabID: uuid)

        XCTAssertEqual(mockFileManager.tabSessionDataDirectoryCalledCount, 1)
    }
}
