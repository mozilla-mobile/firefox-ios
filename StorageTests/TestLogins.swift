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

    func testSearchLogins() {
        let loginA = Login.createWithHostname("alphabet.com", username: "username1", password: "password1")
        let loginB = Login.createWithHostname("alpha.com", username: "username2", password: "password2")
        let loginC = Login.createWithHostname("berry.com", username: "username3", password: "password3")
        let loginD = Login.createWithHostname("candle.com", username: "username4", password: "password4")

        func addLogins() -> Success {
            addLogin(loginA).value
            addLogin(loginB).value
            addLogin(loginC).value
            addLogin(loginD).value
            return succeed()
        }

        func checkAllLogins() -> Success {
            return logins.getAllLogins() >>== { results in
                XCTAssertEqual(results.count, 4)
                return succeed()
            }
        }

        func checkSearchHostnames() -> Success {
            return logins.searchLoginsWithQuery("pha") >>== { results in
                XCTAssertEqual(results.count, 2)
                XCTAssertEqual(results[0]!.hostname, "alpha.com")
                XCTAssertEqual(results[1]!.hostname, "alphabet.com")
                return succeed()
            }
        }

        func checkSearchUsernames() -> Success {
            return logins.searchLoginsWithQuery("username") >>== { results in
                XCTAssertEqual(results.count, 4)
                XCTAssertEqual(results[0]!.username, "username2")
                XCTAssertEqual(results[1]!.username, "username1")
                XCTAssertEqual(results[2]!.username, "username3")
                XCTAssertEqual(results[3]!.username, "username4")
                return succeed()
            }
        }

        func checkSearchPasswords() -> Success {
            return logins.searchLoginsWithQuery("pass") >>== { results in
                XCTAssertEqual(results.count, 4)
                XCTAssertEqual(results[0]!.password, "password2")
                XCTAssertEqual(results[1]!.password, "password1")
                XCTAssertEqual(results[2]!.password, "password3")
                XCTAssertEqual(results[3]!.password, "password4")
                return succeed()
            }
        }

        XCTAssertTrue(addLogins().value.isSuccess)

        XCTAssertTrue(checkAllLogins().value.isSuccess)
        XCTAssertTrue(checkSearchHostnames().value.isSuccess)
        XCTAssertTrue(checkSearchUsernames().value.isSuccess)
        XCTAssertTrue(checkSearchPasswords().value.isSuccess)

        XCTAssertTrue(removeAllLogins().value.isSuccess)
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
                for (index, login) in expected.enumerate() {
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

class TestSQLiteLoginsPerf: XCTestCase {
    var db: BrowserDB!
    var logins: SQLiteLogins!

    override func setUp() {
        super.setUp()
        let files = MockFiles()
        self.db = BrowserDB(filename: "testsqlitelogins.db", files: files)
        self.logins = SQLiteLogins(db: self.db)
    }

    func testLoginsSearchMatchOnePerf() {
        populateTestLogins()

        // Measure time to find one entry amongst the 1000 of them
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: true) {
            for _ in 0...5 {
                self.logins.searchLoginsWithQuery("username500").value
            }
            self.stopMeasuring()
        }

        XCTAssertTrue(removeAllLogins().value.isSuccess)
    }

    func testLoginsSearchMatchAllPerf() {
        populateTestLogins()

        // Measure time to find all matching results
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: true) {
            for _ in 0...5 {
                self.logins.searchLoginsWithQuery("username").value
            }
            self.stopMeasuring()
        }

        XCTAssertTrue(removeAllLogins().value.isSuccess)
    }

    func populateTestLogins() {
        for i in 0..<1000 {
            let login = Login.createWithHostname("website\(i).com", username: "username\(i)", password: "password\(i)")
            addLogin(login).value
        }
    }

    func addLogin(login: LoginData) -> Success {
        log.debug("Add \(login)")
        return logins.addLogin(login)
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
        let loginA1 = Login(guid: guid, hostname: host, username: user, password: "password1")
        loginA1.formSubmitURL = "\(host)/form1/"
        loginA1.usernameField = "afield"

        let loginA2 = Login(guid: guid, hostname: host, username: user, password: "password1")
        loginA2.formSubmitURL = "\(host)/form1/"
        loginA2.usernameField = "somefield"

        let loginB = Login(guid: guid, hostname: host, username: user, password: "password2")
        loginB.formSubmitURL = "\(host)/form1/"

        let loginC = Login(guid: guid, hostname: host, username: user, password: "password")
        loginC.formSubmitURL = "\(host)/form2/"

        XCTAssert(loginA1.isSignificantlyDifferentFrom(loginB))
        XCTAssert(loginA1.isSignificantlyDifferentFrom(loginC))
        XCTAssert(loginA2.isSignificantlyDifferentFrom(loginB))
        XCTAssert(loginA2.isSignificantlyDifferentFrom(loginC))
        XCTAssert(!loginA1.isSignificantlyDifferentFrom(loginA2))
    }

    func testLocalNewStaysNewAndIsRemoved() {
        let guidA = "abcdabcdabcd"
        let loginA1 = Login(guid: guidA, hostname: "http://example.com", username: "username", password: "password")
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
        let loginA1 = ServerLogin(guid: guidA, hostname: "http://example.com", username: "username", password: "password", modified: 1234)
        loginA1.formSubmitURL = "http://example.com/form/"
        loginA1.timesUsed = 3

        XCTAssertTrue(self.logins.applyChangedLogin(loginA1).value.isSuccess)

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
        let loginA2 = ServerLogin(guid: guidA, hostname: "http://example.com", username: "username", password: "newpassword", modified: 2234)
        loginA2.formSubmitURL = "http://example.com/form/"
        loginA2.timesUsed = 4

        XCTAssertTrue(self.logins.applyChangedLogin(loginA2).value.isSuccess)
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
        let newLocalPassword = Login(guid: guidA, hostname: "http://example.com", username: "username", password: "yupyup")
        newLocalPassword.formSubmitURL = "http://example.com/form2/"

        let preUpdate = NSDate.now()

        // Updates always bump our usages, too.
        XCTAssertTrue(self.logins.updateLoginByGUID(guidA, new: newLocalPassword, significant: true).value.isSuccess)

        let localAltered = self.logins.getExistingLocalRecordByGUID(guidA).value.successValue!
        let mirrorAltered = self.logins.getExistingMirrorRecordByGUID(guidA).value.successValue!

        XCTAssertFalse(mirrorAltered!.isSignificantlyDifferentFrom(mirrorUsed!))      // The mirror is unchanged.
        XCTAssertFalse(mirrorAltered!.isSignificantlyDifferentFrom(localUsed!))
        XCTAssertTrue(mirrorAltered!.isOverridden)                                // It's still overridden.

        XCTAssertTrue(localAltered!.isSignificantlyDifferentFrom(localUsed!))
        XCTAssertEqual(localAltered!.password, "yupyup")
        XCTAssertEqual(localAltered!.formSubmitURL!, "http://example.com/form2/")
        XCTAssertTrue(localAltered!.localModified >= preUpdate)
        XCTAssertEqual(localAltered!.syncStatus, SyncStatus.Changed)              // Changes are enough to warrant upload.
        XCTAssertEqual(localAltered!.timesUsed, 6)
        XCTAssertEqual(mirrorAltered!.timesUsed, 4)
    }

    func testDeltas() {
        // Shared.
        let guidA = "abcdabcdabcd"
        let loginA1 = ServerLogin(guid: guidA, hostname: "http://example.com", username: "username", password: "password", modified: 1234)
        loginA1.timeCreated = 1200
        loginA1.timeLastUsed = 1234
        loginA1.timePasswordChanged = 1200
        loginA1.formSubmitURL = "http://example.com/form/"
        loginA1.timesUsed = 3

        let a1a1 = loginA1.deltas(from: loginA1)
        XCTAssertEqual(0, a1a1.nonCommutative.count)
        XCTAssertEqual(0, a1a1.nonConflicting.count)
        XCTAssertEqual(0, a1a1.commutative.count)

        let loginA2 = ServerLogin(guid: guidA, hostname: "http://example.com", username: "username", password: "password", modified: 1235)
        loginA2.timeCreated = 1200
        loginA2.timeLastUsed = 1235
        loginA2.timePasswordChanged = 1200
        loginA2.timesUsed = 4

        let a1a2 = loginA2.deltas(from: loginA1)

        XCTAssertEqual(2, a1a2.nonCommutative.count)
        XCTAssertEqual(0, a1a2.nonConflicting.count)
        XCTAssertEqual(1, a1a2.commutative.count)

        switch a1a2.commutative[0] {
        case let .TimesUsed(increment):
            XCTAssertEqual(increment, 1)
            break
        }
        switch a1a2.nonCommutative[0] {
        case let .FormSubmitURL(to):
            XCTAssertNil(to)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }
        switch a1a2.nonCommutative[1] {
        case let .TimeLastUsed(to):
            XCTAssertEqual(to, 1235)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }

        let loginA3 = ServerLogin(guid: guidA, hostname: "http://example.com", username: "username", password: "something else", modified: 1280)
        loginA3.timeCreated = 1200
        loginA3.timeLastUsed = 1250
        loginA3.timePasswordChanged = 1250
        loginA3.formSubmitURL = "http://example.com/form/"
        loginA3.timesUsed = 5

        let a1a3 = loginA3.deltas(from: loginA1)

        XCTAssertEqual(3, a1a3.nonCommutative.count)
        XCTAssertEqual(0, a1a3.nonConflicting.count)
        XCTAssertEqual(1, a1a3.commutative.count)

        switch a1a3.commutative[0] {
        case let .TimesUsed(increment):
            XCTAssertEqual(increment, 2)
            break
        }

        switch a1a3.nonCommutative[0] {
        case let .Password(to):
            XCTAssertEqual("something else", to)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }
        switch a1a3.nonCommutative[1] {
        case let .TimeLastUsed(to):
            XCTAssertEqual(to, 1250)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }
        switch a1a3.nonCommutative[2] {
        case let .TimePasswordChanged(to):
            XCTAssertEqual(to, 1250)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }

        // Now apply the deltas to the original record and check that they match!
        XCTAssertFalse(loginA1.applyDeltas(a1a2).isSignificantlyDifferentFrom(loginA2))
        XCTAssertFalse(loginA1.applyDeltas(a1a3).isSignificantlyDifferentFrom(loginA3))

        let merged = Login.mergeDeltas(a: (loginA2.serverModified, a1a2), b: (loginA3.serverModified, a1a3))
        let mCCount = merged.commutative.count
        let a2CCount = a1a2.commutative.count
        let a3CCount = a1a3.commutative.count
        XCTAssertEqual(mCCount, a2CCount + a3CCount)

        let mNCount = merged.nonCommutative.count
        let a2NCount = a1a2.nonCommutative.count
        let a3NCount = a1a3.nonCommutative.count
        XCTAssertLessThanOrEqual(mNCount, a2NCount + a3NCount)
        XCTAssertGreaterThanOrEqual(mNCount, max(a2NCount, a3NCount))

        let mFCount = merged.nonConflicting.count
        let a2FCount = a1a2.nonConflicting.count
        let a3FCount = a1a3.nonConflicting.count
        XCTAssertLessThanOrEqual(mFCount, a2FCount + a3FCount)
        XCTAssertGreaterThanOrEqual(mFCount, max(a2FCount, a3FCount))

        switch merged.commutative[0] {
        case let .TimesUsed(increment):
            XCTAssertEqual(1, increment)
        }
        switch merged.commutative[1] {
        case let .TimesUsed(increment):
            XCTAssertEqual(2, increment)
        }

        switch merged.nonCommutative[0] {
        case let .Password(to):
            XCTAssertEqual("something else", to)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }
        switch merged.nonCommutative[1] {
        case let .FormSubmitURL(to):
            XCTAssertNil(to)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }
        switch merged.nonCommutative[2] {
        case let .TimeLastUsed(to):
            XCTAssertEqual(to, 1250)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }
        switch merged.nonCommutative[3] {
        case let .TimePasswordChanged(to):
            XCTAssertEqual(to, 1250)
            break
        default:
            XCTFail("Unexpected non-commutative login field.")
        }

        // Applying the merged deltas gives us the expected login.
        let expected = Login(guid: guidA, hostname: "http://example.com", username: "username", password: "something else")
        expected.timeCreated = 1200
        expected.timeLastUsed = 1250
        expected.timePasswordChanged = 1250
        expected.formSubmitURL = nil
        expected.timesUsed = 6

        let applied = loginA1.applyDeltas(merged)
        XCTAssertFalse(applied.isSignificantlyDifferentFrom(expected))
        XCTAssertFalse(expected.isSignificantlyDifferentFrom(applied))
    }
}