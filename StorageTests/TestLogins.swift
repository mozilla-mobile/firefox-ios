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
        self.db = BrowserDB(filename: "testsqlitelogins.db", files: files)
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
        self.db = BrowserDB(filename: "testsyncablelogins.db", files: files)
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

    func testLocalNewStaysNewAndIsRemoved() {
        let guidA = "abcdabcdabcd"
        var loginA1 = Login(guid: guidA, hostname: "http://example.com", username: "username", password: "password")
        loginA1.formSubmitURL = "http://example.com/form/"
        loginA1.timesUsed = 1
        XCTAssertTrue((self.logins as BrowserLogins).addLogin(loginA1).value.isSuccess)

        let local1 = self.logins.getExistingLocalRecordByGUID(guidA).value.successValue!
        XCTAssertNotNil(local1)
        XCTAssertEqual(local1!.guid, guidA)
        XCTAssertEqual(local1!.syncStatus, SyncStatus.New)
        XCTAssertEqual(local1!.timesUsed, 1)

        XCTAssertTrue(self.logins.addUseOfLoginByGUID(guidA).value.isSuccess)

        // It's still new.
        let local2 = self.logins.getExistingLocalRecordByGUID(guidA).value.successValue!
        XCTAssertNotNil(local2)
        XCTAssertEqual(local2!.guid, guidA)
        XCTAssertEqual(local2!.syncStatus, SyncStatus.New)
        XCTAssertEqual(local2!.timesUsed, 2)

        // It's removed immediately, because it was never synced.
        XCTAssertTrue((self.logins as BrowserLogins).removeLoginByGUID(guidA).value.isSuccess)
        XCTAssertNil(self.logins.getExistingLocalRecordByGUID(guidA).value.successValue!)
    }

    func testApplyLogin() {
        let guidA = "abcdabcdabcd"
        var loginA1 = Login(guid: guidA, hostname: "http://example.com", username: "username", password: "password")
        loginA1.formSubmitURL = "http://example.com/form/"
        loginA1.timesUsed = 3

        XCTAssertTrue(self.logins.applyChangedLogin(loginA1, timestamp: 1234).value.isSuccess)

        let local = self.logins.getExistingLocalRecordByGUID(guidA).value.successValue!
        let mirror = self.logins.getExistingMirrorRecordByGUID(guidA).value.successValue!

        XCTAssertTrue(nil == local)
        XCTAssertTrue(nil != mirror)

        XCTAssertEqual(mirror!.guid, guidA)
        XCTAssertFalse(mirror!.isOverridden)
        XCTAssertEqual(mirror!.serverModified, Timestamp(1234), "Timestamp matches.")
        XCTAssertEqual(mirror!.timesUsed, 3)
        XCTAssertTrue(nil == mirror!.httpRealm)
        XCTAssertTrue(nil == mirror!.passwordField)
        XCTAssertTrue(nil == mirror!.usernameField)
        XCTAssertEqual(mirror!.formSubmitURL!, "http://example.com/form/")
        XCTAssertEqual(mirror!.hostname, "http://example.com")
        XCTAssertEqual(mirror!.username!, "username")
        XCTAssertEqual(mirror!.password, "password")

        // Change it.
        var loginA2 = Login(guid: guidA, hostname: "http://example.com", username: "username", password: "newpassword")
        loginA2.formSubmitURL = "http://example.com/form/"
        loginA2.timesUsed = 4

        XCTAssertTrue(self.logins.applyChangedLogin(loginA2, timestamp: 2234).value.isSuccess)
        let changed = self.logins.getExistingMirrorRecordByGUID(guidA).value.successValue!

        XCTAssertTrue(nil != changed)
        XCTAssertFalse(changed!.isOverridden)
        XCTAssertEqual(changed!.serverModified, Timestamp(2234), "Timestamp is new.")
        XCTAssertEqual(changed!.username!, "username")
        XCTAssertEqual(changed!.password, "newpassword")
        XCTAssertEqual(changed!.timesUsed, 4)

        // Change it locally.
        let preUse = NSDate.now()
        XCTAssertTrue(self.logins.addUseOfLoginByGUID(guidA).value.isSuccess)

        let localUsed = self.logins.getExistingLocalRecordByGUID(guidA).value.successValue!
        let mirrorUsed = self.logins.getExistingMirrorRecordByGUID(guidA).value.successValue!

        XCTAssertNotNil(localUsed)
        XCTAssertNotNil(mirrorUsed)

        XCTAssertEqual(mirrorUsed!.guid, guidA)
        XCTAssertEqual(localUsed!.guid, guidA)
        XCTAssertEqual(mirrorUsed!.password, "newpassword")
        XCTAssertEqual(localUsed!.password, "newpassword")

        XCTAssertTrue(mirrorUsed!.isOverridden)                // It's now overridden.
        XCTAssertEqual(mirrorUsed!.serverModified, Timestamp(2234), "Timestamp is new.")

        XCTAssertTrue(localUsed!.localModified >= preUse)         // Local record is modified.
        XCTAssertEqual(localUsed!.syncStatus, SyncStatus.Synced)  // Uses aren't enough to warrant upload.

        // Uses are local until reconciled.
        XCTAssertEqual(localUsed!.timesUsed, 5)
        XCTAssertEqual(mirrorUsed!.timesUsed, 4)

        // Change the password and form URL locally.
        var newLocalPassword = Login(guid: guidA, hostname: "http://example.com", username: "username", password: "yupyup")
        newLocalPassword.formSubmitURL = "http://example.com/form2/"

        let preUpdate = NSDate.now()
        XCTAssertTrue(self.logins.updateLoginByGUID(guidA, new: newLocalPassword, significant: true).value.isSuccess)

        let localAltered = self.logins.getExistingLocalRecordByGUID(guidA).value.successValue!
        let mirrorAltered = self.logins.getExistingMirrorRecordByGUID(guidA).value.successValue!

        XCTAssertFalse(mirrorAltered!.significantlyDiffersFrom(mirrorUsed!))      // The mirror is unchanged.
        XCTAssertFalse(mirrorAltered!.significantlyDiffersFrom(localUsed!))
        XCTAssertTrue(mirrorAltered!.isOverridden)                                // It's still overridden.

        XCTAssertTrue(localAltered!.significantlyDiffersFrom(localUsed!))
        XCTAssertEqual(localAltered!.password, "yupyup")
        XCTAssertEqual(localAltered!.formSubmitURL!, "http://example.com/form2/")
        XCTAssertTrue(localAltered!.localModified >= preUpdate)
        XCTAssertEqual(localAltered!.syncStatus, SyncStatus.Changed)              // Changes are enough to warrant upload.
        XCTAssertEqual(localAltered!.timesUsed, 5)
        XCTAssertEqual(mirrorAltered!.timesUsed, 4)
    }
}
