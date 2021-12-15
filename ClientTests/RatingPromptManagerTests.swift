// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import StoreKit
import Shared
import Sentry

@testable import Client

class RatingPromptManagerTests: XCTestCase {

    var promptManager: RatingPromptManager!
    var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()

        self.mockProfile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()

        promptManager.reset()
        promptManager = nil
        mockProfile = nil
        Sentry.shared.client = nil
    }

    func testShouldShowPrompt_requiredAreFalse_returnsFalse() {
        setupEnvironment(numberOfSession: 0,
                         hasCumulativeDaysOfUse: false)
        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_withRequiredRequirementsAndOneOptional_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        XCTAssertTrue(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_lessThanSession5_returnsFalse() {
        setupEnvironment(numberOfSession: 4,
                         hasCumulativeDaysOfUse: true,
                         isBrowserDefault: true)
        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_cumulativeDaysOfUseFalse_returnsFalse() {
        setupEnvironment(numberOfSession: 5,
                         hasCumulativeDaysOfUse: false,
                         isBrowserDefault: true)
        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_sentryHasCrashedInLastSession_returnsFalse() {
        setupEnvironment(isBrowserDefault: true)
        Sentry.shared.client = try! CrashingMockSentryClient()

        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_isBrowserDefaultFalse_returnsFalse() {
        setupEnvironment(isBrowserDefault: false)
        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_isBrowserDefaultTrue_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        XCTAssertTrue(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_asSyncAccountTrue_returnsTrue() {
        setupEnvironment(hasSyncAccount: true)
        XCTAssertTrue(promptManager.shouldShowPrompt)
    }

//    func testEngineIsGoogle() {
//
//    }
//
//    func testhasTPStrict() {
//
//    }
//
//    func testHasMinimumBookmarksCount() {
//
//    }
//
//    func testHasMinimumPinnedShortcutsCount() {
//
//    }
//
//    func testHasRequestedInTheLastTwoWeeks() {
//
//    }
//
//    func testRequestCount() {
//
//    }
//
//    func testGoToAppStoreReview() {
//
//    }
}

// MARK: Helpers

private extension RatingPromptManagerTests {

    func setupEnvironment(numberOfSession: Int32 = 5,
                          hasCumulativeDaysOfUse: Bool = true,
                          isBrowserDefault: Bool = false,
                          hasSyncAccount: Bool = false) {

        mockProfile.hasSyncableAccountMock = hasSyncAccount
        mockProfile.prefs.setInt(numberOfSession, forKey: PrefsKeys.SessionCount)
        setupPromptManager(hasCumulativeDaysOfUse: hasCumulativeDaysOfUse)
        RatingPromptManager.isBrowserDefault = isBrowserDefault
    }

    func setupPromptManager(hasCumulativeDaysOfUse: Bool) {
        let mockCounter = CumulativeDaysOfUseCounterMock(hasCumulativeDaysOfUse)
        promptManager = RatingPromptManager(profile: mockProfile,
                                            daysOfUseCounter: mockCounter)
    }
}

class CumulativeDaysOfUseCounterMock: CumulativeDaysOfUseCounter {

    private let hasMockRequiredDaysOfUse: Bool
    init(_ hasRequiredCumulativeDaysOfUse: Bool) {
        self.hasMockRequiredDaysOfUse = hasRequiredCumulativeDaysOfUse
    }

    override var hasRequiredCumulativeDaysOfUse: Bool {
        return hasMockRequiredDaysOfUse
    }
}

class CrashingMockSentryClient: Client {

    convenience init() throws {
        try self.init(dsn: "https://public@sentry.example.com/1")
    }

    override func crashedLastLaunch() -> Bool {
        return true
    }
}
