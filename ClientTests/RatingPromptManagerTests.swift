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

        self.urlOpenerSpy = URLOpenerSpy()
        mockProfile = MockProfile()
        mockProfile._reopen()

        // Make sure engine is set to Google
        let googleEngine = mockProfile.searchEngines.orderedEngines.first(where: { $0.shortName == "Google" })!
        mockProfile.searchEngines.defaultEngine = googleEngine
    }

    override func tearDown() {
        super.tearDown()

        promptManager.reset()
        promptManager = nil
        mockProfile._shutdown()
        mockProfile = nil
        Sentry.shared.client = nil
        self.urlOpenerSpy = nil
    }

    func testShouldShowPrompt_requiredAreFalse_returnsFalse() {
        setupEnvironment(numberOfSession: 0,
                         hasCumulativeDaysOfUse: false)
        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_requiredTrueWithoutOptional_returnsFalse() {
        setupEnvironment()
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

    func testShouldShowPrompt_isBrowserDefaultTrue_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        XCTAssertTrue(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_asSyncAccountTrue_returnsTrue() {
        setupEnvironment(hasSyncAccount: true)
        XCTAssertTrue(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_searchEngineIsNotGoogle_returnsTrue() {
        let fakeEngine = OpenSearchEngine(engineID: "1", shortName: "NotGoogle", image: UIImage(),
                                          searchTemplate: "", suggestTemplate: nil, isCustomEngine: true)
        mockProfile.searchEngines.defaultEngine = fakeEngine
        setupEnvironment()

        XCTAssertTrue(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_hasTPStrict_returnsTrue() {
        mockProfile.prefs.setString(BlockingStrength.strict.rawValue, forKey: ContentBlockingConfig.Prefs.StrengthKey)
        setupEnvironment()

        XCTAssertTrue(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_hasMinimumBookmarksCount_returnsTrue() {
        for i in 0...4 {
            let bookmark = ShareItem(url: "http://www.example.com/\(i)", title: "Example \(i)", favicon: nil)
            _ = mockProfile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID, url: bookmark.url, title: bookmark.title).value
        }

        let expectation = self.expectation(description: "Rating prompt manager data is loaded")
        setupEnvironment(completion: {
            XCTAssertTrue(self.promptManager.shouldShowPrompt)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldShowPrompt_hasMinimumPinnedShortcutsCount_returnsTrue() {
        for i in 0...1 {
            let site = createSite(number: i)
            _ = mockProfile.history.addPinnedTopSite(site)
        }

        let expectation = self.expectation(description: "Rating prompt manager data is loaded")
        setupEnvironment(completion: {
            XCTAssertTrue(self.promptManager.shouldShowPrompt)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldShowPrompt_hasRequestedTwoWeeksAgo_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        promptManager.requestRatingPrompt(at: Date().lastTwoWeek)

        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testShouldShowPrompt_hasRequestedInTheLastTwoWeeks_returnsFalse() {
        setupEnvironment()

        promptManager.requestRatingPrompt(at: Date())
        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testRequestCount() {
        setupEnvironment()

        promptManager.requestRatingPrompt()
        XCTAssertFalse(promptManager.shouldShowPrompt)
    }

    func testGoToAppStoreReview() {
        setupEnvironment()
        promptManager.urlOpener = urlOpenerSpy

        promptManager.goToAppStoreReview()
        XCTAssertEqual(urlOpenerSpy.openURLCount, 1)
    }
}

// MARK: Helpers

private extension RatingPromptManagerTests {

    func setupEnvironment(numberOfSession: Int32 = 5,
                          hasCumulativeDaysOfUse: Bool = true,
                          isBrowserDefault: Bool = false,
                          hasSyncAccount: Bool = false,
                          completion: (() -> Void)? = nil) {

        mockProfile.hasSyncableAccountMock = hasSyncAccount
        mockProfile.prefs.setInt(numberOfSession, forKey: PrefsKeys.SessionCount)
        setupPromptManager(hasCumulativeDaysOfUse: hasCumulativeDaysOfUse, completion: completion)
        RatingPromptManager.isBrowserDefault = isBrowserDefault
    }

    func setupPromptManager(hasCumulativeDaysOfUse: Bool, completion: (() -> Void)? = nil) {
        let mockCounter = CumulativeDaysOfUseCounterMock(hasCumulativeDaysOfUse)
        promptManager = RatingPromptManager(profile: mockProfile,
                                            daysOfUseCounter: mockCounter,
                                            dataLoadingCompletion: completion)
    }

    func createSite(number: Int) -> Site {
        let site = Site(url: "http://s\(number)ite\(number).com/foo", title: "A \(number)")
        site.id = number
        site.guid = "abc\(number)def"

        return site
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

    var openURLCount = 0
    func open(_ url: URL) {
        openURLCount += 1
    }
}
