// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Storage

class MockRustLogins: RustLogins {
    var logins = [Int: LoginEntry]()
    var id = 0

    override func reopenIfClosed() -> NSError? {
        return nil
    }

    override func addLogin(login: LoginEntry) -> Deferred<Maybe<String>> {
        let deferred = Deferred<Maybe<String>>()
        queue.async {
            self.id += 1
            self.logins[self.id] = login
            deferred.fill(Maybe(success: String(self.id)))
        }
        return deferred
    }

    public func mockListLogins() -> Deferred<Maybe<[LoginEntry]>> {
        let deferred = Deferred<Maybe<[LoginEntry]>>()
        queue.async {
            let list = self.logins.map { (key, value) in
                return value
            }
            deferred.fill(Maybe(success: list))
        }
        return deferred
    }

    override func wipeLocalEngine() -> Success {
        let deferred = Success()
        queue.async {
            self.logins.removeAll()
            self.id = 0
            deferred.fill(Maybe(success: ()))
        }
        return deferred
    }

    override func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        let deferred = Deferred<Maybe<Bool>>()
        queue.async {
            deferred.fill(Maybe(success: !self.logins.isEmpty))
        }
        return deferred
    }
}

class MockListLoginsFailure: RustLogins {
    override func listLogins() -> Deferred<Maybe<[EncryptedLogin]>> {
        let deferred = Deferred<Maybe<[EncryptedLogin]>>()
        queue.async {
            let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
            deferred.fill(Maybe(failure: error as MaybeErrorType))
        }
        return deferred
    }
}

class MockListLoginsEmpty: RustLogins {
    override func listLogins() -> Deferred<Maybe<[EncryptedLogin]>> {
        let deferred = Deferred<Maybe<[EncryptedLogin]>>()
        queue.async {
            deferred.fill(Maybe(success: [EncryptedLogin]()))
        }
        return deferred
    }
}

class RustLoginsTests: XCTestCase {
    var files: FileAccessor!
    var logins: RustLogins!
    var mockLogins: MockRustLogins!
    var mockListLoginsFailure: MockListLoginsFailure!
    var mockListLoginsEmpty: MockListLoginsEmpty!

    let keychain = MZKeychainWrapper.sharedClientAppContainerKeychain
    let canaryPhraseKey = "canaryPhrase"
    let loginKeychainKey = "appservices.key.logins.perfield"

    override func setUp() {
        super.setUp()
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true).appendingPathComponent("testLoginsPerField.db").path
            try? files.remove("testLoginsPerField.db")

            logins = RustLogins(databasePath: databasePath)
            _ = logins.reopenIfClosed()

            mockLogins = MockRustLogins(databasePath: databasePath)

            self.keychain.removeObject(forKey: self.canaryPhraseKey, withAccessibility: .afterFirstUnlock)
            self.keychain.removeObject(forKey: self.loginKeychainKey, withAccessibility: .afterFirstUnlock)
        } else {
            XCTFail("Could not retrieve root directory")
        }
    }

    override func tearDown() {
        super.tearDown()
        self.keychain.removeObject(forKey: self.canaryPhraseKey, withAccessibility: .afterFirstUnlock)
        self.keychain.removeObject(forKey: self.loginKeychainKey, withAccessibility: .afterFirstUnlock)
    }

    func setUpMockListLoginsFailure() {
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true).appendingPathComponent("testLoginsPerField.db").path
            try? files.remove("testLoginsPerField.db")

            mockListLoginsFailure = MockListLoginsFailure(databasePath: databasePath)
            _ = mockListLoginsFailure.reopenIfClosed()
        } else {
            XCTFail("Could not retrieve root directory")
        }
    }

    func setUpMockListLoginsEmpty() {
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true).appendingPathComponent("testLoginsPerField.db").path
            try? files.remove("testLoginsPerField.db")

            mockListLoginsEmpty = MockListLoginsEmpty(databasePath: databasePath)
            _ = mockListLoginsEmpty.reopenIfClosed()
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

    func testGetStoredKeyWithKeychainReset() {
        // Here we are checking that, if the database has login records and the logins
        // key data has been removed from the keychain, calling logins.getStoredKey will
        // remove the logins from the database, recreate logins key data, and return the
        // new key.

        let login = LoginEntry(fromJSONDict: [
            "hostname": "https://example.com",
            "formSubmitUrl": "https://example.com",
            "username": "username",
            "password": "password"
        ])
        mockLogins.addLogin(login: login).upon { addResult in
            XCTAssertTrue(addResult.isSuccess)
            XCTAssertNotNil(addResult.successValue)
        }

        mockLogins.mockListLogins().upon { listResult in
            XCTAssertTrue(listResult.isSuccess)
            XCTAssertNotNil(listResult.successValue)
            XCTAssertEqual(listResult.successValue!.count, 1)
        }

        // Simulate losing the key data while a logins record exists in the database
        self.keychain.removeObject(forKey: self.canaryPhraseKey, withAccessibility: .afterFirstUnlock)
        self.keychain.removeObject(forKey: self.loginKeychainKey, withAccessibility: .afterFirstUnlock)
        XCTAssertNil(self.keychain.string(forKey: self.canaryPhraseKey))
        XCTAssertNil(self.keychain.string(forKey: self.loginKeychainKey))

        let expectation = expectation(description: "\(#function)\(#line)")
        mockLogins.getStoredKey { result in
            // Check that we successfully retrieved a key
            XCTAssertNotNil(try? result.get())

            // check that the logins were wiped from the database
            self.mockLogins.mockListLogins().upon { listResult2 in
                XCTAssertTrue(listResult2.isSuccess)
                XCTAssertNotNil(listResult2.successValue)
                XCTAssertEqual(listResult2.successValue!.count, 0)
            }

            // Check that new key data was created
            XCTAssertNotNil(self.keychain.string(forKey: self.canaryPhraseKey))
            XCTAssertNotNil(self.keychain.string(forKey: self.loginKeychainKey))

            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testVerifyWithFailedList() {
        // Mocking a failed call to listLogins within verifyLogins
        setUpMockListLoginsFailure()

        let exp = expectation(description: "\(#function)\(#line)")
        mockListLoginsFailure.verifyLogins { result in
            exp.fulfill()

            // Check that verification failed
            XCTAssertFalse(result)
        }
        waitForExpectations(timeout: 5)
    }

    func testVerifyWithNoLogins() {
        setUpMockListLoginsEmpty()

        let exp = expectation(description: "\(#function)\(#line)")
        mockListLoginsEmpty.verifyLogins { result in
            exp.fulfill()

            // Check that verification succeeds when there are no saved logins
            XCTAssertTrue(result)
        }
        waitForExpectations(timeout: 5)
    }
}
