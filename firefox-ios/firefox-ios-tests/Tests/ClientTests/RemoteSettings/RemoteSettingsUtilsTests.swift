// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client
import Foundation
import XCTest
import WebKit
import Shared
import Common
import Storage

class RemoteSettingsUtilsTests: XCTestCase {
    var mockLogger: MockLogger!
    var remoteSettingsUtils: RemoteSettingsUtils!

    override func setUp() {
        super.setUp()
        mockLogger = MockLogger()
        remoteSettingsUtils = RemoteSettingsUtils(logger: mockLogger)
    }

    override func tearDown() {
        remoteSettingsUtils = nil
        mockLogger = nil
        super.tearDown()
    }

    // Test: Successful fetch of local records
    func testFetchLocalRecordsSuccess() async {
        let result: [PasswordRuleRecord]? = await remoteSettingsUtils.fetchLocalRecords(for: .passwordRules)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?.first?.domain, "ccs-grp.com")
        XCTAssertEqual(result?.last?.domain, "lepida.it")
    }

    // Test: Error when file not found
//    func testFetchLocalRecordsFileNotFound() async {
//        enum TestDataType: RemoteDataTypeRecord {
//            case nonExistentFile
//        }
//
//        let result: [PasswordRuleRecord]? = await remoteSettingsUtils.fetchLocalRecords(for: TestDataType.nonExistentFile)
//
//        XCTAssertNil(result)
//    }
//
//    // Test: Error decoding the JSON
//    func testFetchLocalRecordsDecodingError() async {
//        enum TestDataType: RemoteDataTypeRecord {
//            case invalidJSONFormat
//        }
//
//        let result: [PasswordRuleRecord]? = await remoteSettingsUtils.fetchLocalRecords(for: TestDataType.invalidJSONFormat)
//
//        XCTAssertNil(result)
//    }
}
