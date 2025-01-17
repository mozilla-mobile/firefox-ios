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

    override func setUp() {
        super.setUp()

        prefs = MockProfilePrefs()
        logger = CrashingMockLogger()
        urlOpenerSpy = URLOpenerSpy()
        userDefaults = MockUserDefaults()
    }

    override func tearDown() {
        prefs.clearAll()
        prefs = nil
        logger = nil
        urlOpenerSpy = nil
        userDefaults = nil

        super.tearDown()
    }

    func testShouldShowPrompt_forceShow() {
        let subject = createSubject()
        userDefaults.set(true, forKey: PrefsKeys.ForceShowAppReviewPromptOverride)
        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_requiredAreFalse_returnsFalse() {
        let subject = createSubject()
        prefs.setInt(0, forKey: PrefsKeys.Session.Count)
        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_withRequiredRequirementsAndOneOptional_returnsTrue() {
        let subject = createSubject()
        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_lessThanSession5_returnsFalse() {
        let subject = createSubject()
        prefs.setInt(0, forKey: PrefsKeys.Session.Count)
        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_loggerHasCrashedInLastSession_returnsFalse() {
        let subject = createSubject()
        logger?.enableCrashOnLastLaunch = true

        subject.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    // MARK: Number of times asked

    func testShouldShowPrompt_hasRequestedInTheLastTwoWeeks_returnsFalse() {
        let subject = createSubject()
        subject.showRatingPromptIfNeeded(at: Date().lastTwoWeek)
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_requestCountTwiceCountIsAtOne() {
        let subject = createSubject()
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

    func createSubject(file: StaticString = #file, line: UInt = #line) -> RatingPromptManager {
        let subject = RatingPromptManager(prefs: prefs, logger: logger, userDefaults: userDefaults)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    var ratingPromptOpenCount: Int {
        UserDefaults.standard.object(
            forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptRequestCount.rawValue
        ) as? Int ?? 0
    }

    var lastCrashDateKey: Date? {
        UserDefaults.standard.object(
            forKey: RatingPromptManager.UserDefaultsKey.keyLastCrashDateKey.rawValue
        ) as? Date
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
