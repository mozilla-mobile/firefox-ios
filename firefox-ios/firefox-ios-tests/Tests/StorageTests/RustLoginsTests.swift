// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import XCTest

@testable import Storage

// FIXME: FXIOS-14312 Class is not thread safe
class RustLoginsTests: XCTestCase, @unchecked Sendable {
    var files: FileAccessor!
    var logins: RustLogins!
    let login = LoginEntry(fromJSONDict: [
        "hostname": "https://example.com",
        "formSubmitUrl": "https://example.com",
        "username": "username",
        "password": "password"
    ])

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

    func testListLogins() {
        let expectation = XCTestExpectation(description: "addLogin")
        logins.addLogin(login: login) { result in
            switch result {
            case .success(let login):
                XCTAssertNotNil(login)
            case .failure:
                XCTFail("Add login failed")
            }
            expectation.fulfill()
        }

        wait(for: [expectation])
        let listLoginsExpectation = XCTestExpectation(description: "listLogins")
        logins.listLogins { result in
            switch result {
            case .success(let logins):
                XCTAssertNotNil(logins)
                XCTAssertEqual(logins.count, 1)
            case .failure:
                XCTFail("List logins failed")
            }
            listLoginsExpectation.fulfill()
        }
        wait(for: [listLoginsExpectation])
    }

    func testAddLogin() {
        let expectation = XCTestExpectation(description: "addLogin")
        logins.addLogin(login: login) { result in
            switch result {
            case .success(let login):
                XCTAssertNotNil(login)
                self.logins.getLogin(id: login!.id) { result in
                    switch result {
                    case .success(let fetchedLogin):
                        XCTAssertNotNil(fetchedLogin)
                        XCTAssertEqual(fetchedLogin!.id, login!.id)
                        expectation.fulfill()
                    case .failure:
                        XCTFail("Get login failed")
                    }
                }
            case .failure:
                XCTFail("Add login failed")
            }
        }

        wait(for: [expectation])
    }

    func testUpdateLogin() {
        let expectation = XCTestExpectation(description: "addLogin")

        logins.addLogin(login: login) { result in
            switch result {
            case .success(let addedLogin):
                XCTAssertNotNil(addedLogin)
                let updatedLogin = LoginEntry(
                        origin: addedLogin!.hostname,
                        httpRealm: addedLogin!.httpRealm,
                        formActionOrigin: addedLogin!.formSubmitUrl,
                        usernameField: addedLogin!.usernameField,
                        passwordField: addedLogin!.passwordField,
                        password: "password2",
                        username: ""
                )
                self.logins.updateLogin(id: addedLogin!.id, login: updatedLogin) { result in
                    switch result {
                    case .success(let updateLogin):
                        self.logins.getLogin(id: updateLogin!.id) { result in
                            switch result {
                            case .success(let login):
                                XCTAssertEqual(updateLogin!.id, login?.id)
                                expectation.fulfill()
                            case .failure:
                                XCTFail("Call to get login failed")
                            }
                        }
                    case .failure:
                        XCTFail("Call to update login failed")
                    }
                }
            case .failure:
                XCTFail("Call to add login failed")
            }
        }
        wait(for: [expectation])
    }

    func testDeleteLogin() {
        let expectation = XCTestExpectation(description: "addLogin")
        logins.addLogin(login: login) { result in
            switch result {
            case .success(let login):
                XCTAssertNotNil(login)
                self.logins.deleteLogin(id: login!.id) { result in
                    switch result {
                    case .success:
                        self.logins.getLogin(id: login!.id) { result in
                            switch result {
                            case .success(let login):
                                XCTAssertNil(login)
                                expectation.fulfill()
                            case .failure:
                                XCTFail("Get login failed")
                            }
                        }
                    case .failure:
                        XCTFail("Delete login failed")
                    }
                }
            case .failure:
                XCTFail("Add login failed")
            }
        }
        wait(for: [expectation])
    }

    func testDeleteMultipleLogins() {
        // Add three logins to delete, one after another to avoid crashing (FIXME: FXIOS-14323 / Github #31023)
        for i in 0..<3 {
            let expectation = XCTestExpectation(description: "Add login \(i)")
            let login = RustLoginsTests.loginFactory(number: i)

            logins.addLogin(login: login) { result in
                switch result {
                case .success(let login):
                    XCTAssertNotNil(login)
                    expectation.fulfill()
                case .failure:
                    XCTFail("Add login \(i) failed")
                }
            }

            wait(for: [expectation], timeout: 2)
        }

        let deleteExpectation = XCTestExpectation(description: "Deleting all entries")

        // Fetch all the logins and then delete them
        self.logins.listLogins { [logins] listLoginsResult in
            switch listLoginsResult {
            case .success(let allLogins):
                XCTAssertEqual(allLogins.count, 3, "Three logins must have been added")

                // Now try to delete multiple logins
                logins?.deleteLogins(ids: allLogins.map(\.id)) { deleteLoginsResult in
                    switch deleteLoginsResult {
                    case .success(let deletedLogins):
                        XCTAssertEqual(deletedLogins.count, 3, "Three results should have been deleted")
                        deleteExpectation.fulfill()
                    case .failure:
                        XCTFail("Deleting all logins failed")
                    }
                }
            case .failure:
                XCTFail()
            }
        }

        wait(for: [deleteExpectation], timeout: 2)
    }

    static func loginFactory(number: Int) -> LoginEntry {
        return LoginEntry(fromJSONDict: [
            "hostname": "https://example\(number).com",
            "formSubmitUrl": "https://example\(number).com",
            "username": "username\(number)",
            "password": "password\(number)"
        ])
    }
}
