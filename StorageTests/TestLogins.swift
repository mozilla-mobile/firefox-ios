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
    let login = Login.createWithHostname("hostname1", username: "username1", password: "password1")

    override func setUp() {
        super.setUp()

        let files = MockFiles()
        self.logins = SQLiteLogins(files: files)
    }

    func testAddLogin() {
        log.debug("Created \(self.login)")
        let expectation = self.expectationWithDescription("Add login")

        addLogin(login) >>>
            getLoginsFor(login.protectionSpace, expected: [login]) >>>
            done(login.protectionSpace, expectation: expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testGetOrder() {
        let expectation = self.expectationWithDescription("Add login")
        let login2 = Login.createWithHostname("hostname1", username: "username2", password: "password2")

        addLogin(login) >>>
            addLoginCurried(login2) >>>
            getLoginsFor(login.protectionSpace, expected: [login2, login]) >>>
            done(login.protectionSpace, expectation: expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testRemoveLogin() {
        let expectation = self.expectationWithDescription("Remove login")

        addLogin(login) >>>
            removeLogin(login) >>>
            getLoginsFor(login.protectionSpace, expected: []) >>>
            done(login.protectionSpace, expectation: expectation)

        waitForExpectationsWithTimeout(10.0, handler: nil)
    }

    func testUpdateLogin() {
        let expectation = self.expectationWithDescription("Update login")
        let updated = Login.createWithHostname("hostname1", username: "username1", password: "password3")

        addLogin(login) >>>
            updateLogin(updated) >>>
            getLoginsFor(login.protectionSpace, expected: [updated]) >>>
            done(login.protectionSpace, expectation: expectation)

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

    func done(protectionSpace: NSURLProtectionSpace, expectation: XCTestExpectation)() -> Success {
        return removeAllLogins() >>>
            getLoginsFor(protectionSpace, expected: []) >>> {
                expectation.fulfill()
                return succeed()
        }
    }

    // Note: These functions are all curried so that we pass arguments, but still chain them below
    func addLogin(login: LoginData) -> Success {
        log.debug("Add \(login)")
        return logins.addLogin(login)
    }

    func addLoginCurried(login: LoginData) -> (() -> Success) {
        return { return self.addLogin(login) }
    }

    func updateLogin(login: LoginData) -> (() -> Success) {
        return {
            log.debug("Update \(login)")
            var usage = login as! LoginUsageData
            usage.timePasswordChanged = NSDate.nowMicroseconds()
            return self.logins.updateLogin(login)
        }
    }

    func addUseDelayed(login: LoginData, time: UInt32) -> (() -> Success) {
        return {
            sleep(time)
            if var usageData = login as? LoginUsageData {
                usageData.timeLastUsed = NSDate.nowMicroseconds()
            }
            let res = self.logins.addUseOf(login)
            sleep(time)
            return res
        }
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

    func removeLogin(login: LoginData) -> (() -> Success) {
        return {
            log.debug("Remove \(login)")
            return self.logins.removeLogin(login)
        }
    }

    func removeAllLogins() -> Success {
        log.debug("Remove All")
        return self.logins.removeAll()
    }
}