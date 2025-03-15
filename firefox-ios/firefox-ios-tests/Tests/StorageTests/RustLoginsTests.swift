// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import XCTest

@testable import Storage

// This class uses the logic enabled with the `useRustKeychain` feature flag. It will replace
// LegacyRustLoginsTests once the feature flag is removed.
class RustLoginsTests: XCTestCase {
    var files: FileAccessor!
    var logins: RustLogins!

    override func setUp() {
        super.setUp()
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(
                fileURLWithPath: rootDirectory,
                isDirectory: true
            ).appendingPathComponent("testLoginsPerField.db").path
            try? files.remove("testLoginsPerField.db")

            logins = RustLogins(databasePath: databasePath,
                                rustKeychainEnabled: true)
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
                origin: login!.hostname,
                httpRealm: login!.httpRealm,
                formActionOrigin: login!.formSubmitUrl,
                usernameField: login!.usernameField,
                passwordField: login!.passwordField,
                password: "password2",
                username: ""
        )

        let updateResult = logins.updateLogin(id: login!.id, login: updatedLogin).value
        XCTAssertTrue(updateResult.isSuccess)
        let getResult2 = logins.getLogin(id: login!.id).value
        XCTAssertTrue(getResult2.isSuccess)
        XCTAssertNotNil(getResult2.successValue!)
        let password = getResult2.successValue!!.password
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

// This class tests the rust components keychain logic that uses MZKeychainWrapper.
// Once the nimbus logic for the `useRustKeychain` flag is removed, LegacyRustLoginsTests
// will be obsolete.
class LegacyRustLoginsTests: XCTestCase {
    var files: FileAccessor!
    var logins: RustLogins!

    override func setUp() {
        super.setUp()
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(
                fileURLWithPath: rootDirectory,
                isDirectory: true
            ).appendingPathComponent("testLoginsPerField.db").path
            try? files.remove("testLoginsPerField.db")

            logins = RustLogins(databasePath: databasePath)
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
                origin: login!.hostname,
                httpRealm: login!.httpRealm,
                formActionOrigin: login!.formSubmitUrl,
                usernameField: login!.usernameField,
                passwordField: login!.passwordField,
                password: "password2",
                username: ""
        )

        let updateResult = logins.updateLogin(id: login!.id, login: updatedLogin).value
        XCTAssertTrue(updateResult.isSuccess)
        let getResult2 = logins.getLogin(id: login!.id).value
        XCTAssertTrue(getResult2.isSuccess)
        XCTAssertNotNil(getResult2.successValue!)
        let password = getResult2.successValue!!.password
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
