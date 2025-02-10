// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import StoreKit
import XCTest

@testable import Client

class RatingPromptManagerTests: XCTestCase {
    var urlOpenerSpy: URLOpenerSpy!
    var prefs: MockProfilePrefs!
    var logger: CrashingMockLogger!
    var userDefaults: MockUserDefaults!
    var crashTracker: MockCrashTracker!
    var subject: RatingPromptManager!

    override func setUp() {
        super.setUp()

        prefs = MockProfilePrefs()
        logger = CrashingMockLogger()
        urlOpenerSpy = URLOpenerSpy()
        userDefaults = MockUserDefaults()
        crashTracker = MockCrashTracker()
        subject = RatingPromptManager(prefs: prefs,
                                      crashTracker: crashTracker,
                                      logger: logger,
                                      userDefaults: userDefaults)
    }

    override func tearDown() {
        prefs.clearAll()
        subject.reset()
        prefs = nil
        logger = nil
        urlOpenerSpy = nil
        userDefaults = nil
        crashTracker = nil
        subject = nil

        super.tearDown()
    }

    func testShouldShowPrompt_forceShow() {
        userDefaults.set(true, forKey: PrefsKeys.ForceShowAppReviewPromptOverride)
        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_requiredAreFalse_returnsFalse() {
        prefs.setInt(0, forKey: PrefsKeys.Session.Count)
        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_withRequiredRequirements_returnsTrue() {
        prefs.setInt(30, forKey: PrefsKeys.Session.Count)
        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_loggerHasCrashedInLastSession_returnsFalse() {
        crashTracker.mockHasCrashed = true
        prefs.setInt(30, forKey: PrefsKeys.Session.Count)

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_currentLastRequestDate_returnsFalse() {
        prefs.setInt(30, forKey: PrefsKeys.Session.Count)
        userDefaults.set(Date(), forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue)

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_pastDateLastRequestDate_returnsTrue() {
        prefs.setInt(30, forKey: PrefsKeys.Session.Count)
        let pastDate = Calendar.current.date(byAdding: .day, value: -61, to: Date()) ?? Date()
        userDefaults.set(pastDate, forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue)

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_hasRequestedInTheLastTwoWeeks_returnsFalse() {
        prefs.setInt(30, forKey: PrefsKeys.Session.Count)
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        userDefaults.set(twoWeeksAgo,
                         forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue)

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_hasNotReachedSecondThreshold_returnsFalse() {
        userDefaults.set(RatingPromptManager.Constants.secondThreshold,
                         forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptThreshold.rawValue)
        prefs.setInt(31, forKey: PrefsKeys.Session.Count)

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_reachedSecondThreshold_returnsTrue() {
        userDefaults.set(RatingPromptManager.Constants.secondThreshold,
                         forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptThreshold.rawValue)
        prefs.setInt(91, forKey: PrefsKeys.Session.Count)

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_hasNotReachedThirdThreshold_returnsFalse() {
        userDefaults.set(RatingPromptManager.Constants.thirdThreshold,
                         forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptThreshold.rawValue)
        prefs.setInt(91, forKey: PrefsKeys.Session.Count)

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_reachedThirdThreshold_returnsTrue() {
        userDefaults.set(RatingPromptManager.Constants.thirdThreshold,
                         forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptThreshold.rawValue)
        prefs.setInt(121, forKey: PrefsKeys.Session.Count)

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_requestCountTwiceCountIsAtOne() {
        prefs.setInt(30, forKey: PrefsKeys.Session.Count)
        subject.showRatingPromptIfNeeded()
        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    // MARK: App Store

    func testGoToAppStoreReview() {
        RatingPromptManager.goToAppStoreReview(with: urlOpenerSpy)

        XCTAssertEqual(urlOpenerSpy.openURLCount, 1)
        XCTAssertEqual(
            urlOpenerSpy.capturedURL?.absoluteString,
            "https://itunes.apple.com/app/id\(AppInfo.appStoreId)?action=write-review"
        )
    }

    // MARK: - Setup helpers

    var ratingPromptOpenCount: Int {
        userDefaults.object(
            forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptRequestCount.rawValue
        ) as? Int ?? 0
    }
}

// MARK: - CrashingMockLogger
class CrashingMockLogger: Logger {
    func setup(sendCrashReports: Bool) {}
    func configure(crashManager: CrashManager) {}
    func copyLogsToDocuments() {}
    func logCustomError(error: Error) {}
    func deleteCachedLogFiles() {}

    var enableCrashOnLastLaunch = false
    var crashedLastLaunch: Bool {
        return enableCrashOnLastLaunch
    }

    func log(_ message: String,
             level: LoggerLevel,
             category: LoggerCategory,
             extra: [String: String]? = nil,
             description: String? = nil,
             file: String = #file,
             function: String = #function,
             line: Int = #line) {}
}

// MARK: - URLOpenerSpy
class URLOpenerSpy: URLOpenerProtocol {
    var capturedURL: URL?
    var openURLCount = 0
    func open(_ url: URL) {
        capturedURL = url
        openURLCount += 1
    }
}
