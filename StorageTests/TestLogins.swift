/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest
import XCGLogger

private let log = XCGLogger.defaultInstance()

class TestSQLiteLogins: XCTestCase {
    var db: BrowserDB!
    var logins: SQLiteLogins!
    let login = Login.createWithHostname("hostname1", username: "username1", password: "password1")

    override func setUp() {
        super.setUp()

        let files = MockFiles()
        self.db = BrowserDB(files: files)
        self.logins = SQLiteLogins(db: self.db)

        let expectation = self.expectationWithDescription("Remove all logins.")
        self.removeAllLogins().upon({ res in expectation.fulfill() })
        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testAddLogin() {
        log.debug("Created \(self.login)")
        let expectation = self.expectationWithDescription("Add login")

        addLogin(login) >>>
            getLoginsFor(login.protectionSpace, expected: [login]) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testGetOrder() {
        let expectation = self.expectationWithDescription("Add login")

        // Different GUID.
        let login2 = Login.createWithHostname("hostname1", username: "username2", password: "password2")

        addLogin(login) >>>
            { self.addLogin(login2) } >>>
            getLoginsFor(login.protectionSpace, expected: [login2, login]) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testRemoveLogin() {
        let expectation = self.expectationWithDescription("Remove login")

        addLogin(login) >>>
            removeLogin(login) >>>
            getLoginsFor(login.protectionSpace, expected: []) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testUpdateLogin() {
        let expectation = self.expectationWithDescription("Update login")
        let updated = Login.createWithHostname("hostname1", username: "username1", password: "password3")
        updated.guid = self.login.guid

        addLogin(login) >>>
            updateLogin(updated) >>>
            getLoginsFor(login.protectionSpace, expected: [updated]) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    /*
    func testAddUseOfLogin() {
        let expectation = self.expectationWithDescription("Add visit")

        if var usageData = login as? LoginUsageData {
            usageData.timeCreated = NSDate.nowMicroseconds()
        }

        addLogin(login) >>>
            addUseDelayed(login, time: 1) >>>
            getLoginDetailsFor(login, expected: login as! LoginUsageData) >>>
            done(login.protectionSpace, expectation: expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }
    */

    func done(expectation: XCTestExpectation)() -> Success {
        return removeAllLogins()
           >>> getLoginsFor(login.protectionSpace, expected: [])
           >>> {
                expectation.fulfill()
                return succeed()
        }
    }

    // Note: These functions are all curried so that we pass arguments, but still chain them below
    func addLogin(login: LoginData) -> Success {
        log.debug("Add \(login)")
        return logins.addLogin(login)
    }

    func updateLogin(login: LoginData)() -> Success {
        log.debug("Update \(login)")
        return logins.updateLoginByGUID(login.guid, new: login, significant: true)
    }

    func addUseDelayed(login: Login, time: UInt32)() -> Success {
        sleep(time)
        login.timeLastUsed = NSDate.nowMicroseconds()
        let res = logins.addUseOfLoginByGUID(login.guid)
        sleep(time)
        return res
    }

    func getLoginsFor(protectionSpace: NSURLProtectionSpace, expected: [LoginData]) -> (() -> Success) {
        return {
            log.debug("Get logins for \(protectionSpace)")
            return self.logins.getLoginsForProtectionSpace(protectionSpace) >>== { results in
                XCTAssertEqual(expected.count, results.count)
                for (index, login) in enumerate(expected) {
                    XCTAssertEqual(results[index]!.username!, login.username!)
                    XCTAssertEqual(results[index]!.hostname, login.hostname)
                    XCTAssertEqual(results[index]!.password, login.password)
                }
                return succeed()
            }
        }
    }

    /*
    func getLoginDetailsFor(login: LoginData, expected: LoginUsageData) -> (() -> Success) {
        return {
            log.debug("Get details for \(login)")
            let deferred = self.logins.getUsageDataForLogin(login)
            log.debug("Final result \(deferred)")
            return deferred >>== { l in
                log.debug("Got cursor")
                XCTAssertLessThan(expected.timePasswordChanged - l.timePasswordChanged, 10)
                XCTAssertLessThan(expected.timeLastUsed - l.timeLastUsed, 10)
                XCTAssertLessThan(expected.timeCreated - l.timeCreated, 10)
                return succeed()
            }
        }
    }
    */

    func removeLogin(login: LoginData)() -> Success {
        log.debug("Remove \(login)")
        return logins.removeLoginByGUID(login.guid)
    }

    func removeAllLogins() -> Success {
        log.debug("Remove All")
        // Because we don't want to just mark them as deleted.
        return self.db.run("DELETE FROM \(TableLoginsMirror)") >>>
            { self.db.run("DELETE FROM \(TableLoginsLocal)") }
    }
}

class TestSyncableLogins: XCTestCase {
    var db: BrowserDB!
    var logins: SQLiteLogins!

    override func setUp() {
        super.setUp()

        let files = MockFiles()
        self.db = BrowserDB(files: files)
        self.logins = SQLiteLogins(db: self.db)

        let expectation = self.expectationWithDescription("Remove all logins.")
        self.removeAllLogins().upon({ res in expectation.fulfill() })
        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func removeAllLogins() -> Success {
        log.debug("Remove All")
        // Because we don't want to just mark them as deleted.
        return self.db.run("DELETE FROM \(TableLoginsMirror)") >>>
            { self.db.run("DELETE FROM \(TableLoginsLocal)") }
    }

    func testDiffers() {
        let guid = "abcdabcdabcd"
        let host = "http://example.com"
        let user = "username"
        var loginA1 = Login(guid: guid, hostname: host, username: user, password: "password1")
        loginA1.formSubmitURL = "\(host)/form1/"
        loginA1.usernameField = "afield"

        var loginA2 = Login(guid: guid, hostname: host, username: user, password: "password1")
        loginA2.formSubmitURL = "\(host)/form1/"
        loginA2.usernameField = "somefield"

        var loginB = Login(guid: guid, hostname: host, username: user, password: "password2")
        loginB.formSubmitURL = "\(host)/form1/"

        var loginC = Login(guid: guid, hostname: host, username: user, password: "password")
        loginC.formSubmitURL = "\(host)/form2/"

        XCTAssert(loginA1.significantlyDiffersFrom(loginB))
        XCTAssert(loginA1.significantlyDiffersFrom(loginC))
        XCTAssert(loginA2.significantlyDiffersFrom(loginB))
        XCTAssert(loginA2.significantlyDiffersFrom(loginC))
        XCTAssert(!loginA1.significantlyDiffersFrom(loginA2))
    }

    func testApplyLogin() {
        var loginA = Login(guid: "abcdabcdabcd", hostname: "http://example.com", username: "username", password: "password")
        loginA.formSubmitURL = "http://example.com/form/"

        XCTAssertTrue(self.logins.applyChangedLogin(loginA, timestamp: 1234).value.isSuccess)

        let local = self.logins.getExistingLocalRecordByGUID("abcdabcdabcd").value.successValue!
        let mirror = self.logins.getExistingMirrorRecordByGUID("abcdabcdabcd").value.successValue!

        XCTAssertTrue(nil == local)
        XCTAssertEqual(mirror!.serverModified, Timestamp(1234), "Timestamp matches.")
    }
}
