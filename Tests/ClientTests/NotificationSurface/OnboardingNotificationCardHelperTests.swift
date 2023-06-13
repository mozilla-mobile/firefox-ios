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
        super.tearDown()
        AppContainer.shared.reset()
        nimbusUtility = nil
    }

    func testHelper_fromOnboarding_noNotificationCard_returnsTrue() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeSync)
        let expectedResult = true
        let subject = createSubject()

        let result = subject.askForPermissionDuringSync(isOnboarding: true)

        XCTAssertEqual(result, expectedResult)
    }

    func testHelper_fromUpgrade_noNotificationCard_returnsFalse() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeSync)
        let expectedResult = false
        let subject = createSubject()

        let result = subject.askForPermissionDuringSync(isOnboarding: false)

        XCTAssertEqual(result, expectedResult)
    }

    func testHelper_fromOnboarding_withNotificationCard_returnsFalse() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let expectedResult = false
        let subject = createSubject()

        let result = subject.askForPermissionDuringSync(isOnboarding: true)

        XCTAssertEqual(result, expectedResult)
    }

    // MARK: - Helper
    private func createSubject() -> OnboardingNotificationCardHelper {
        let subject = OnboardingNotificationCardHelper()

        return subject
    }
}
