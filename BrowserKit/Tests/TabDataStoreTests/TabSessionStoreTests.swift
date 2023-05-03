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
        await subject.saveTabSession(tabID: uuid, sessionData: dataFile)
        let path = mockFileManager.tabSessionDataDirectory()!.appendingPathComponent("tab-" + uuid.uuidString)

        let data = try? Data(contentsOf: path)
        XCTAssertEqual(data?.count, 100)
    }
}
