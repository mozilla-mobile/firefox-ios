// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
import Shared
@testable import Client
@testable import Storage

class RustLoginsTests: XCTestCase {
    var files: FileAccessor!
    var logins: RustLogins!
    var encryptionKey: String!
    
    override func setUp() {
        files = MockFiles()
        
        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let sqlCipherDatabasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true).appendingPathComponent("testlogins.db").path
            try? files.remove("testlogins.db")
            
            let databasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true).appendingPathComponent("testLoginsPerField.db").path
            try? files.remove("testLoginsPerField.db")

            if let key = try? createKey() {
                encryptionKey = key
            } else {
                XCTFail("Encryption key wasn't created")
            }
            
            logins = RustLogins(sqlCipherDatabasePath: sqlCipherDatabasePath, databasePath: databasePath)
            _ = logins.reopenIfClosed()
            
        } else {
            XCTFail("Could not retrieve root directory")
        }
    }

    func addLogin() -> Deferred<Maybe<String>> {
        let login = LoginEntry(fromJSONDict: [
            "hostname": "https://example.com",
            "formSubmitUrl": "https://example.com",
            "username": "username",
            "password": "password"
        ])
        return logins.addLogin(login: login)
    }

    func testListLogins() {
        let listResult1 = logins.listLogins().value
        XCTAssertTrue(listResult1.isSuccess)
        XCTAssertNotNil(listResult1.successValue)
        XCTAssertEqual(listResult1.successValue!.count, 0)
        let addResult = addLogin().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let listResult2 = logins.listLogins().value
        XCTAssertTrue(listResult2.isSuccess)
        XCTAssertNotNil(listResult2.successValue)
        XCTAssertEqual(listResult2.successValue!.count, 1)
    }

    func testAddLogin() {
        let addResult = addLogin().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult = logins.getLogin(id: addResult.successValue!).value
        XCTAssertTrue(getResult.isSuccess)
        XCTAssertNotNil(getResult.successValue!)
        XCTAssertEqual(getResult.successValue!!.id, addResult.successValue!)
    }

    func testUpdateLogin() {
        let addResult = addLogin().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult1 = logins.getLogin(id: addResult.successValue!).value
        XCTAssertTrue(getResult1.isSuccess)
        XCTAssertNotNil(getResult1.successValue!)
        let login = getResult1.successValue!
        XCTAssertEqual(login!.id, addResult.successValue!)
        
        let updatedLogin = LoginEntry(
            fromLoginEntryFlattened: LoginEntryFlattened(
                id: "",
                hostname: login!.hostname,
                password: "password2",
                username: "",
                httpRealm: login!.httpRealm,
                formSubmitUrl: login!.formSubmitUrl,
                usernameField: login!.usernameField,
                passwordField: login!.passwordField
            )
        )
        
        let updateResult = logins.updateLogin(id: login!.id, login: updatedLogin).value
        XCTAssertTrue(updateResult.isSuccess)
        let getResult2 = logins.getLogin(id: login!.id).value
        XCTAssertTrue(getResult2.isSuccess)
        XCTAssertNotNil(getResult2.successValue!)
        let password = getResult2.successValue!!.decryptedPassword
        XCTAssertEqual(password, "password2")
    }

    func testDeleteLogin() {
        let addResult = addLogin().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult1 = logins.getLogin(id: addResult.successValue!).value
        XCTAssertTrue(getResult1.isSuccess)
        XCTAssertNotNil(getResult1.successValue!)
        let login = getResult1.successValue!
        XCTAssertEqual(login!.id, addResult.successValue!)
        let deleteResult = logins.deleteLogin(id: login!.id).value
        XCTAssertTrue(deleteResult.isSuccess)
        XCTAssertNotNil(deleteResult.successValue!)
        XCTAssertTrue(deleteResult.successValue!)
        let getResult2 = logins.getLogin(id: login!.id).value
        XCTAssertTrue(getResult2.isSuccess)
        XCTAssertNil(getResult2.successValue!)
    }
}
