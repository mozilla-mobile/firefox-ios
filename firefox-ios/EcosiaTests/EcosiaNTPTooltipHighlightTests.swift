// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia
@testable import Client

class EcosiaNTPTooltipHighlightTests: XCTestCase {

    var user: Ecosia.User!

    override func setUpWithError() throws {
        try? FileManager().removeItem(at: FileManager.user)
        user = .init()
        user.firstTime = false
    }

    func testFirstTimeReturnsNil() throws {
        user.firstTime = true
        XCTAssertNil(NTPTooltip.highlight(for: user))
    }

    func testGotClaimed() throws {
        user.referrals.isNewClaim = true
        XCTAssert(NTPTooltip.highlight(for: user) == .gotClaimed)
    }

    func testSuccessfulInvite() throws {
        user.referrals.claims = 1
        XCTAssert(NTPTooltip.highlight(for: user) == .successfulInvite)
    }

    func testReferralSpotlight() throws {
        user.install = Calendar.current.date(byAdding: .day, value: -4, to: .init())!
        XCTAssert(NTPTooltip.highlight(for: user) == .referralSpotlight)
    }

    func testImpactIntro() throws {
        user.showImpactIntro()
        XCTAssert(NTPTooltip.highlight(for: user) == .collectiveImpactIntro)
    }

    func testFallthrough() throws {
        user.hideImpactIntro()
        XCTAssertNil(NTPTooltip.highlight(for: user))
    }
}
