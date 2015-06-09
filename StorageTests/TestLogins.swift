/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest
import XCGLogger

private let log = XCGLogger.defaultInstance()

class TestSQLiteLogins: XCTestCase {
    var logins: Logins!
    let login = Login(hostname: "hostname1", username: "username1", password: "password1")

    override func setUp() {
        super.setUp()

        let files = MockFiles()
        let db = BrowserDB(files: files)
        self.logins = SQLiteLogins(db: db)
    }

    func testAddLogin() {
        let expectation = self.expectationWithDescription("Add login")

        addLogin(login)() >>>
            getLoginsFor(login.protectionSpace, expected: [login]) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testGetOrder() {
        let expectation = self.expectationWithDescription("Add login")
        let login2 = Login(hostname: "hostname1", username: "username2", password: "password2")

        addLogin(login)() >>>
            addLogin(login2) >>>
            getLoginsFor(login.protectionSpace, expected: [login2, login]) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testRemoveLogin() {
        let expectation = self.expectationWithDescription("Remove login")

        addLogin(login)() >>>
            removeLogin(login) >>>
            getLoginsFor(login.protectionSpace, expected: []) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testUpdateLogin() {
        let expectation = self.expectationWithDescription("Update login")
        let updated = Login(hostname: "hostname1", username: "username1", password: "password3")

        login.timeCreated = NSDate.nowMicroseconds()
        login.timeLastUsed = NSDate.nowMicroseconds()
        addLogin(login)() >>>
            updateLogin(updated) >>>
            getLoginsFor(login.protectionSpace, expected: [updated]) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    /* XXX: Trying to get the usage data for a login throws EXC_BAD_ACCESS. Punting on this for now.
    func testAddUseOfLogin() {
        let expectation = self.expectationWithDescription("Add visit")

        login.timeCreated = NSDate.nowMicroseconds()
        addLogin(login)() >>>
            addUseDelayed(login, time: 1) >>>
            getLoginDetailsFor(login, expected: login) >>>
            done(expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }
    */

    func done(expectation: XCTestExpectation)() -> Success {
        return removeAllLogins() >>>
            getLoginsFor(login.protectionSpace, expected: []) >>> {
                expectation.fulfill()
                return succeed()
        }
    }

    // Note: These functions are all curried so that we pass arguments, but still chain them below
    func addLogin(login: Login)() -> Success {
        log.debug("Add \(login)")
        return logins.addLogin(login)
    }

    func updateLogin(login: Login)() -> Success {
        log.debug("Update \(login)")
        login.timePasswordChanged = NSDate.nowMicroseconds()
        return logins.updateLogin(login)
    }

    func addUseDelayed(login: Login, time: UInt32)() -> Success {
        sleep(time)
        login.timeLastUsed = NSDate.nowMicroseconds()
        let res = logins.addUseOf(login)
        sleep(time)
        return res
    }

    func getLoginsFor(protectionSpace: NSURLProtectionSpace, expected: [LoginData])() -> Success {
        log.debug("Get logins for \(protectionSpace)")
        return logins.getLoginsForProtectionSpace(login.protectionSpace) >>== { results in
            XCTAssertEqual(expected.count, results.count)
            for (index, login) in enumerate(expected) {
                XCTAssertEqual(results[index]!.username!, login.username!)
                XCTAssertEqual(results[index]!.hostname, login.hostname)
                XCTAssertEqual(results[index]!.password, login.password)
            }
            return succeed()
        }
    }

    /*
    func getLoginDetailsFor(login: Login, expected: LoginUsageData)() -> Success {
        log.debug("Get details for \(login)")
        let deferred = logins.getUsageDataForLogin(login)
        log.debug("Final result \(deferred)")
        return deferred >>== { login in
            log.debug("Got cursor")
            XCTAssertEqual(expected.timePasswordChanged, login.timePasswordChanged)
            XCTAssertEqual(expected.timeLastUsed, login.timeLastUsed)
            XCTAssertEqual(expected.timeCreated, login.timeCreated)
            return succeed()
        }
    }
    */

    func removeLogin(login: Login)() -> Success {
        log.debug("Remove \(login)")
        return logins.removeLogin(login)
    }

    func removeAllLogins() -> Success {
        log.debug("Remove All")
        return logins.removeAll()
    }
}