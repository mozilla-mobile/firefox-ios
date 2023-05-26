// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class OnboardingNotificationHelperTests: XCTestCase {
    var nimbusUtility: NimbusOnboardingConfigUtility!
    typealias cards = NimbusOnboardingConfigUtility.CardOrder

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        nimbusUtility = NimbusOnboardingConfigUtility()
    }

    override func tearDown() {
        super.tearDown()
        nimbusUtility.clearNimbus()
        nimbusUtility = nil
    }

    func testHelper_fromOnboarding_noNotificationCard_returnsTrue() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeSync)
        let expectedResult = true

        let result = OnboardingNotificationCardHelper()
            .askForPermissionDuringSync(isOnboarding: true)

        XCTAssertEqual(result, expectedResult)
    }

    func testHelper_fromUpgrade_noNotificationCard_returnsFalse() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeSync)
        let expectedResult = false

        let result = OnboardingNotificationCardHelper()
            .askForPermissionDuringSync(isOnboarding: false)

        XCTAssertEqual(result, expectedResult)
    }

    func testHelper_fromOnboarding_withNotificationCard_returnsFalse() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationsSync)
        let expectedResult = false

        let result = OnboardingNotificationCardHelper()
            .askForPermissionDuringSync(isOnboarding: true)

        XCTAssertEqual(result, expectedResult)
    }
}
