// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import StoreKit
import Shared
import Sentry
import Storage

@testable import Client

class RatingPromptManagerTests: XCTestCase {

    var urlOpenerSpy: URLOpenerSpy!
    var promptManager: RatingPromptManager!
    var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()

        urlOpenerSpy = URLOpenerSpy()
        mockProfile = MockProfile()
        mockProfile._reopen()

        // Make sure engine is set to Google
        let googleEngine = mockProfile.searchEngines.orderedEngines.first(where: { $0.shortName == "Google" })!
        mockProfile.searchEngines.defaultEngine = googleEngine
    }

    override func tearDown() {
        super.tearDown()

        promptManager?.reset()
        promptManager = nil
        mockProfile._shutdown()
        mockProfile = nil
        Sentry.shared.client = nil
        urlOpenerSpy = nil
    }

    func testShouldShowPrompt_requiredAreFalse_returnsFalse() {
        setupEnvironment(numberOfSession: 0,
                         hasCumulativeDaysOfUse: false)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_requiredTrueWithoutOptional_returnsFalse() {
        setupEnvironment()
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_withRequiredRequirementsAndOneOptional_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_lessThanSession5_returnsFalse() {
        setupEnvironment(numberOfSession: 4,
                         hasCumulativeDaysOfUse: true,
                         isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_cumulativeDaysOfUseFalse_returnsFalse() {
        setupEnvironment(numberOfSession: 5,
                         hasCumulativeDaysOfUse: false,
                         isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_sentryHasCrashedInLastSession_returnsFalse() {
        setupEnvironment(isBrowserDefault: true)
        Sentry.shared.client = try! CrashingMockSentryClient()

        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_isBrowserDefaultTrue_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_asSyncAccountTrue_returnsTrue() {
        setupEnvironment(hasSyncAccount: true)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_searchEngineIsNotGoogle_returnsTrue() {
        let fakeEngine = OpenSearchEngine(engineID: "1", shortName: "NotGoogle", image: UIImage(),
                                          searchTemplate: "", suggestTemplate: nil, isCustomEngine: true)
        mockProfile.searchEngines.defaultEngine = fakeEngine
        setupEnvironment()

        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_hasTPStrict_returnsTrue() {
        mockProfile.prefs.setString(BlockingStrength.strict.rawValue, forKey: ContentBlockingConfig.Prefs.StrengthKey)
        setupEnvironment()

        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_hasMinimumBookmarksCount_returnsTrue() {
        let expectation = self.expectation(description: "Rating prompt manager data is loaded")
        for i in 0...4 {
            let bookmark = ShareItem(url: "http://www.example.com/\(i)", title: "Example \(i)", favicon: nil)
            _ = mockProfile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID, url: bookmark.url, title: bookmark.title).value
        }

        setupEnvironment()
        promptManager.updateData(dataLoadingCompletion: { [weak self] in
            guard let promptManager = self?.promptManager else {
                XCTFail("Should have reference to promptManager")
                return
            }

            promptManager.showRatingPromptIfNeeded()
            XCTAssertEqual(self?.ratingPromptOpenCount, 1)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldShowPrompt_hasMinimumPinnedShortcutsCount_returnsTrue() {
        let expectation = self.expectation(description: "Rating prompt manager data is loaded")
        for i in 0...1 {
            let site = createSite(number: i)
            _ = mockProfile.history.addPinnedTopSite(site)
        }

        setupEnvironment()
        promptManager.updateData(dataLoadingCompletion: { [weak self] in
            guard let promptManager = self?.promptManager else {
                XCTFail("Should have reference to promptManager")
                return 
            }

            promptManager.showRatingPromptIfNeeded()
            XCTAssertEqual(self?.ratingPromptOpenCount, 1)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldShowPrompt_hasRequestedTwoWeeksAgo_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded(at: Date().lastTwoWeek)
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_hasRequestedInTheLastTwoWeeks_returnsFalse() {
        setupEnvironment()

        promptManager.showRatingPromptIfNeeded(at: Date().lastTwoWeek)
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_requestCountTwiceCountIsAtOne() {
        setupEnvironment(isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded()
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testGoToAppStoreReview() {
        RatingPromptManager.goToAppStoreReview(with: urlOpenerSpy)

        XCTAssertEqual(urlOpenerSpy.openURLCount, 1)
        XCTAssertEqual(urlOpenerSpy.capturedURL?.absoluteString, "https://itunes.apple.com/app/id\(AppInfo.appStoreId)?action=write-review")
    }
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

    func createSite(number: Int) -> Site {
        let site = Site(url: "http://s\(number)ite\(number).com/foo", title: "A \(number)")
        site.id = number
        site.guid = "abc\(number)def"

        return site
    }

    var ratingPromptOpenCount: Int {
        UserDefaults.standard.object(forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptRequestCount.rawValue) as? Int ?? 0
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

class URLOpenerSpy: URLOpenerProtocol {

    var capturedURL: URL?
    var openURLCount = 0
    func open(_ url: URL) {
        capturedURL = url
        openURLCount += 1
    }
}
