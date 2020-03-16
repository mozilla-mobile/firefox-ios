/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import XCTest

@testable import MozillaAppServices

class LoginsTests: XCTestCase {
    func getTestStorage() -> LoginsStorage {
        let directory = NSTemporaryDirectory()
        let filename = "testdb-\(UUID().uuidString).db"
        let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(filename)
        // Note: SQLite supports using file: urls, so this works. (Maybe we should allow
        // passing in a URL argument too?)
        return LoginsStorage(databasePath: fileURL.absoluteString)
    }

    override func setUp() {
        // This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // This method is called after the invocation of each test method in the class.
    }

    func testBadEncryptionKey() {
        let storage = getTestStorage()
        var dbOpened = true
        do {
            try storage.unlock(withEncryptionKey: "foofoofoo")
        } catch {
            XCTFail("Failed to setup db")
        }

        try! storage.lock()

        do {
            try storage.unlock(withEncryptionKey: "zebra")
        } catch {
            dbOpened = false
        }

        XCTAssertFalse(dbOpened, "Bad key unlocked the db!")
    }

    func testLoginRecordNil() {
        let storage = getTestStorage()
        try! storage.unlock(withEncryptionKey: "test123")
        let id0 = try! storage.add(login: LoginRecord(
            id: "",
            password: "hunter2",
            hostname: "https://www.example.com",
            username: "cooluser33",
            formSubmitURL: "https://www.example.com/login",
            httpRealm: nil,
            timesUsed: nil,
            timeLastUsed: nil,
            timeCreated: nil,
            timePasswordChanged: nil,
            usernameField: "users_name",
            passwordField: "users_password"
        ))

        let record0 = try! storage.get(id: id0)!
        XCTAssertNil(record0.httpRealm)
        // We fixed up the formSubmitURL to just be the origin part of the url.
        XCTAssertEqual(record0.formSubmitURL, "https://www.example.com")

        let id1 = try! storage.add(login: LoginRecord(
            id: "",
            password: "hunter3",
            hostname: "https://www.example2.com",
            username: "cooluser44",
            formSubmitURL: nil,
            httpRealm: "Something Something",
            timesUsed: nil,
            timeLastUsed: nil,
            timeCreated: nil,
            timePasswordChanged: nil,
            usernameField: "",
            passwordField: ""
        ))

        let record1 = try! storage.get(id: id1)!

        XCTAssertNil(record1.formSubmitURL)
        XCTAssertEqual(record1.httpRealm, "Something Something")
    }

    func testLoginEnsureValid() {
        let storage = getTestStorage()
        try! storage.unlock(withEncryptionKey: "test123")

        let id0 = try! storage.add(login: LoginRecord(
            id: "",
            password: "hunter5",
            hostname: "https://www.example5.com",
            username: "cooluser55",
            formSubmitURL: "https://www.example5.com",
            httpRealm: nil,
            timesUsed: nil,
            timeLastUsed: nil,
            timeCreated: nil,
            timePasswordChanged: nil,
            usernameField: "users_name",
            passwordField: "users_password"
        ))

        let dupeLogin = LoginRecord(
            id: "",
            password: "hunter3",
            hostname: "https://www.example5.com",
            username: "cooluser55",
            formSubmitURL: "https://www.example5.com",
            httpRealm: nil,
            timesUsed: nil,
            timeLastUsed: nil,
            timeCreated: nil,
            timePasswordChanged: nil,
            usernameField: "users_name",
            passwordField: "users_password"
        )

        let nullValueLogin = LoginRecord(
            id: "",
            password: "hunter3",
            hostname: "https://www.example6.com",
            username: "\0cooluser56",
            formSubmitURL: "https://www.example6.com",
            httpRealm: nil,
            timesUsed: nil,
            timeLastUsed: nil,
            timeCreated: nil,
            timePasswordChanged: nil,
            usernameField: "users_name",
            passwordField: "users_password"
        )

        XCTAssertThrowsError(try storage.ensureValid(login: dupeLogin))
        XCTAssertThrowsError(try storage.ensureValid(login: nullValueLogin))
    }
}
