/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import Shared
import Deferred

@testable import Storage

class RustLoginsTests: XCTestCase {
    var files: FileAccessor!
    var logins: RustLogins!
    
    override func setUp() {
        files = MockFiles()

        let databasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("testlogins.db").path
        try? files.remove("testlogins.db")

        let encryptionKey = Bytes.generateRandomBytes(256).base64EncodedString
        logins = RustLogins(databasePath: databasePath, encryptionKey: encryptionKey)
        _ = logins.reopenIfClosed()
    }

    func addLogin() -> Deferred<Maybe<String>> {
        let login = LoginRecord(fromJSONDict: [
            "hostname": "https://example.com",
            "formSubmitURL": "https://example.com",
            "username": "username",
            "password": "password"
        ])
        login.httpRealm = nil
        return logins.add(login: login)
    }

    func testListLogins() {
        let listResult1 = logins.list().value
        XCTAssertTrue(listResult1.isSuccess)
        XCTAssertNotNil(listResult1.successValue)
        XCTAssertEqual(listResult1.successValue!.count, 0)
        let addResult = addLogin().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let listResult2 = logins.list().value
        XCTAssertTrue(listResult2.isSuccess)
        XCTAssertNotNil(listResult2.successValue)
        XCTAssertEqual(listResult2.successValue!.count, 1)
    }

    func testAddLogin() {
        let addResult = addLogin().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult = logins.get(id: addResult.successValue!).value
        XCTAssertTrue(getResult.isSuccess)
        XCTAssertNotNil(getResult.successValue!)
        XCTAssertEqual(getResult.successValue!!.id, addResult.successValue!)
    }

    func testUpdateLogin() {
        let addResult = addLogin().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult1 = logins.get(id: addResult.successValue!).value
        XCTAssertTrue(getResult1.isSuccess)
        XCTAssertNotNil(getResult1.successValue!)
        let login = getResult1.successValue!
        XCTAssertEqual(login!.id, addResult.successValue!)
        login!.password = "password2"
        let updateResult = logins.update(login: login!).value
        XCTAssertTrue(updateResult.isSuccess)
        let getResult2 = logins.get(id: login!.id).value
        XCTAssertTrue(getResult2.isSuccess)
        XCTAssertNotNil(getResult2.successValue!)
        XCTAssertEqual(getResult2.successValue!!.password, "password2")
    }

    func testDeleteLogin() {
        let addResult = addLogin().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult1 = logins.get(id: addResult.successValue!).value
        XCTAssertTrue(getResult1.isSuccess)
        XCTAssertNotNil(getResult1.successValue!)
        let login = getResult1.successValue!
        XCTAssertEqual(login!.id, addResult.successValue!)
        let deleteResult = logins.delete(id: login!.id).value
        XCTAssertTrue(deleteResult.isSuccess)
        XCTAssertNotNil(deleteResult.successValue!)
        XCTAssertTrue(deleteResult.successValue!)
        let getResult2 = logins.get(id: login!.id).value
        XCTAssertTrue(getResult2.isSuccess)
        XCTAssertNil(getResult2.successValue!)
    }
}
