// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class ReferralsModelTests: XCTestCase {
    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    func testInitWithCode() {
        let expect = expectation(description: "")
        User.shared.referrals = .init(code: "avocado1234")
        User.queue.async {
            let user = User()
            XCTAssertEqual(0, user.referrals.claims)
            XCTAssertEqual("avocado1234", user.referrals.code)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testUpdateReferred() {
        let expect = expectation(description: "")
        User.shared.referrals = .init(code: "avocado12")
        User.queue.async {
            User.shared.referrals.claims += 1
            User.queue.async {
                let user = User()
                XCTAssertEqual(1, user.referrals.claims)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testCount() {
        var referrals = Referrals.Model()
        XCTAssertEqual(0, referrals.count)
        referrals.claims = 1
        XCTAssertEqual(1, referrals.count)
        referrals.isClaimed = true
        XCTAssertEqual(2, referrals.count)
    }

    func testClaims() {
        var referrals = Referrals.Model()
        XCTAssertEqual(0, referrals.newClaims)
        referrals.claims = 2
        XCTAssertEqual(2, referrals.newClaims)
        referrals.accept()
        XCTAssertEqual(0, referrals.newClaims)
    }
}
