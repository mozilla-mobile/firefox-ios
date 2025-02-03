// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared
import Common

@testable import Client

class OnboardingNotificationCardHelperTests: XCTestCase {
    var nimbusUtility: NimbusOnboardingTestingConfigUtility!
    typealias cards = NimbusOnboardingTestingConfigUtility.CardOrder

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        nimbusUtility = NimbusOnboardingTestingConfigUtility()
    }

    override func tearDown() {
        AppContainer.shared.reset()
        nimbusUtility = nil
        super.tearDown()
    }

    func testHelper_fromOnboarding_withNotificationCard_returnsTrue() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let expectedResult = true
        let subject = createSubject()

        let result = subject.notificationCardIsInOnboarding()

        XCTAssertEqual(result, expectedResult)
    }

    func testHelper_fromUpgrade_noNotificationCard_returnsFalse() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeSync)
        let expectedResult = false
        let subject = createSubject()

        let result = subject.notificationCardIsInOnboarding()

        XCTAssertEqual(result, expectedResult)
    }

    func testShouldAskForPermission_WhenNotOnboarding() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let telemetryObj = TelemetryWrapper.EventObject.home
        let subject = createSubject()
        let result = subject.shouldAskForNotificationsPermission(telemetryObj: telemetryObj)

        XCTAssertTrue(result)
    }

    func testShouldNotAskForPermission_WhenOnboarding() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let telemetryObj = TelemetryWrapper.EventObject.onboarding
        let subject = createSubject()
        let result = subject.shouldAskForNotificationsPermission(telemetryObj: telemetryObj)

        XCTAssertFalse(result)
    }

    // MARK: - Helper
    private func createSubject() -> OnboardingNotificationCardHelper {
        let subject = OnboardingNotificationCardHelper()

        return subject
    }
}
