// swiftlint:disable force_try
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class UpgradeTests: XCTestCase {
    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    func testFrom5_3To6() {
        var old = User5_3()
        old.install = .init(timeIntervalSince1970: 123)
        old.news = .init(timeIntervalSince1970: 456)
        old.analyticsId = .init()
        old.marketCode = .bg_bg
        old.adultFilter = .strict
        old.autoComplete = false
        old.firstTime = false
        old.personalized = true
        old.migrated = true
        old.id = "hello world"
        old.treeCount = 909
        old.state[User5_3.Key.welcomeScreen.rawValue] = "\(false)"

        try! JSONEncoder().encode(old).write(to: FileManager.user, options: .atomic)

        let upgraded = User()
        XCTAssertEqual(old.install, upgraded.install)
        XCTAssertEqual(old.news, upgraded.news)
        XCTAssertEqual(old.analyticsId, upgraded.analyticsId)
        XCTAssertEqual(old.marketCode, upgraded.marketCode)
        XCTAssertEqual(old.adultFilter, upgraded.adultFilter)
        XCTAssertEqual(old.autoComplete, upgraded.autoComplete)
        XCTAssertEqual(old.firstTime, upgraded.firstTime)
        XCTAssertEqual(old.personalized, upgraded.personalized)
        XCTAssertEqual(old.migrated, upgraded.migrated)
        XCTAssertEqual(old.id, upgraded.id)
        XCTAssertEqual(old.treeCount, upgraded.searchCount)
        XCTAssertEqual(old.state, upgraded.state)
        XCTAssertEqual(Referrals.Model(), upgraded.referrals)
    }
}
// swiftlint:enable force_try
