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
    var promptManager: RatingPromptManager!
    var mockProfile: MockProfile!
    var createdGuids: [String] = []
    var logger: CrashingMockLogger!
    var mockDispatchGroup: MockDispatchGroup!

    override func setUp() {
        super.setUp()

        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        urlOpenerSpy = URLOpenerSpy()
    }

    override func tearDown() {
        createdGuids = []
        promptManager?.reset()
        promptManager = nil
        mockProfile?.shutdown()
        mockProfile = nil
        logger = nil
        urlOpenerSpy = nil
        super.tearDown()
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

    func testShouldShowPrompt_loggerHasCrashedInLastSession_returnsFalse() {
        setupEnvironment(isBrowserDefault: true)
        logger?.enableCrashOnLastLaunch = true

        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 0)
    }

    func testShouldShowPrompt_isBrowserDefaultTrue_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    func testShouldShowPrompt_hasTPStrict_returnsTrue() {
        setupEnvironment()
        mockProfile.prefs.setString(
            BlockingStrength.strict.rawValue,
            forKey: ContentBlockingConfig.Prefs.StrengthKey
        )

        promptManager.showRatingPromptIfNeeded()
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    // MARK: Bookmarks

    func testShouldShowPrompt_hasNotMinimumMobileBookmarksCount_returnsFalse() {
        setupEnvironment()
        createBookmarks(bookmarkCount: 2, withRoot: BookmarkRoots.MobileFolderGUID)
        updateData(expectedRatingPromptOpenCount: 0)
    }

    func testShouldShowPrompt_hasMinimumMobileBookmarksCount_returnsTrue() {
        _ = XCTSkip("flakey test")
//        setupEnvironment()
//        createBookmarks(bookmarkCount: 5, withRoot: BookmarkRoots.MobileFolderGUID)
//        updateData(expectedRatingPromptOpenCount: 1)
    }

    func testShouldShowPrompt_hasOtherBookmarksCount_returnsFalse() {
        setupEnvironment()
        createBookmarks(bookmarkCount: 5, withRoot: BookmarkRoots.ToolbarFolderGUID)
        updateData(expectedRatingPromptOpenCount: 0)
    }

    func testShouldShowPrompt_has5FoldersInMobileBookmarks_returnsFalse() {
        setupEnvironment()
        createFolders(folderCount: 5, withRoot: BookmarkRoots.MobileFolderGUID)
        updateData(expectedRatingPromptOpenCount: 0)
    }

    func testShouldShowPrompt_has5SeparatorsInMobileBookmarks_returnsFalse() {
        setupEnvironment()
        createSeparators(separatorCount: 5, withRoot: BookmarkRoots.MobileFolderGUID)
        updateData(expectedRatingPromptOpenCount: 0)
    }

    func testShouldShowPrompt_hasRequestedTwoWeeksAgo_returnsTrue() {
        setupEnvironment(isBrowserDefault: true)
        promptManager.showRatingPromptIfNeeded(at: Date().lastTwoWeek)
        XCTAssertEqual(ratingPromptOpenCount, 1)
    }

    // MARK: Number of times asked

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

    // MARK: App Store

    func testGoToAppStoreReview() {
        RatingPromptManager.goToAppStoreReview(with: urlOpenerSpy)

        XCTAssertEqual(urlOpenerSpy.openURLCount, 1)
        XCTAssertEqual(
            urlOpenerSpy.capturedURL?.absoluteString,
            "https://itunes.apple.com/app/id\(AppInfo.appStoreId)?action=write-review"
        )
    }
}

// MARK: - Places helpers

private extension RatingPromptManagerTests {
    func createFolders(folderCount: Int, withRoot root: String, file: StaticString = #filePath, line: UInt = #line) {
        (1...folderCount).forEach { index in
            mockProfile.places.createFolder(
                parentGUID: root,
                title: "Folder \(index)",
                position: nil
            ).uponQueue(.main) { guid in
                guard let guid = guid.successValue else {
                    XCTFail("CreateFolder method did not return GUID", file: file, line: line)
                    return
                }
                self.createdGuids.append(guid)
            }
        }

        // Make sure the folders we create are deleted at the end of the test
        addTeardownBlock { [weak self] in
            self?.createdGuids.forEach { guid in
                _ = self?.mockProfile.places.deleteBookmarkNode(guid: guid)
            }
        }
    }

    func createSeparators(
        separatorCount: Int,
        withRoot root: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        (1...separatorCount).forEach { index in
            mockProfile.places.createSeparator(parentGUID: root, position: nil).uponQueue(.main) { guid in
                guard let guid = guid.successValue else {
                    XCTFail("CreateFolder method did not return GUID", file: file, line: line)
                    return
                }
                self.createdGuids.append(guid)
            }
        }

        // Make sure the separators we create are deleted at the end of the test
        addTeardownBlock { [weak self] in
            self?.createdGuids.forEach { guid in
                _ = self?.mockProfile.places.deleteBookmarkNode(guid: guid)
            }
        }
    }

    func createBookmarks(bookmarkCount: Int, withRoot root: String) {
        (1...bookmarkCount).forEach { index in
            let bookmark = ShareItem(url: "http://www.example.com/\(index)", title: "Example \(index)")
            _ = mockProfile.places.createBookmark(parentGUID: root,
                                                  url: bookmark.url,
                                                  title: bookmark.title,
                                                  position: nil).value
        }

        // Make sure the bookmarks we create are deleted at the end of the test
        addTeardownBlock { [weak self] in
            self?.deleteBookmarks(bookmarkCount: bookmarkCount)
        }
    }

    func deleteBookmarks(bookmarkCount: Int) {
        (1...bookmarkCount).forEach { index in
            _ = mockProfile.places.deleteBookmarksWithURL(url: "http://www.example.com/\(index)")
        }
    }

    func updateData(expectedRatingPromptOpenCount: Int, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = self.expectation(description: "Rating prompt manager data is loaded")
        promptManager.updateData(dataLoadingCompletion: { [weak self] in
            guard let promptManager = self?.promptManager else {
                XCTFail("Should have reference to promptManager", file: file, line: line)
                return
            }

            promptManager.showRatingPromptIfNeeded()
            XCTAssertEqual(
                self?.ratingPromptOpenCount,
                expectedRatingPromptOpenCount,
                file: file,
                line: line
            )
            expectation.fulfill()
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
}

// MARK: - Setup helpers

private extension RatingPromptManagerTests {
    func setupEnvironment(numberOfSession: Int32 = 5,
                          hasCumulativeDaysOfUse: Bool = true,
                          isBrowserDefault: Bool = false,
                          functionName: String = #function) {
        mockProfile = MockProfile(databasePrefix: functionName)
        mockProfile.reopen()

        mockProfile.prefs.setInt(numberOfSession, forKey: PrefsKeys.Session.Count)
        setupPromptManager(hasCumulativeDaysOfUse: hasCumulativeDaysOfUse)
        RatingPromptManager.isBrowserDefault = isBrowserDefault
    }

    func setupPromptManager(hasCumulativeDaysOfUse: Bool) {
        let mockCounter = CumulativeDaysOfUseCounterMock(hasCumulativeDaysOfUse)
        logger = CrashingMockLogger()
        mockDispatchGroup = MockDispatchGroup()
        promptManager = RatingPromptManager(profile: mockProfile,
                                            daysOfUseCounter: mockCounter,
                                            logger: logger,
                                            group: mockDispatchGroup)
    }

    func createSite(number: Int) -> Site {
        let site = Site(url: "http://s\(number)ite\(number).com/foo", title: "A \(number)")
        site.id = number
        site.guid = "abc\(number)def"

        return site
    }

    var ratingPromptOpenCount: Int {
        UserDefaults.standard.object(
            forKey: RatingPromptManager.UserDefaultsKey.keyRatingPromptRequestCount.rawValue
        ) as? Int ?? 0
    }
}

// MARK: - CumulativeDaysOfUseCounterMock
class CumulativeDaysOfUseCounterMock: CumulativeDaysOfUseCounter {
    private let hasMockRequiredDaysOfUse: Bool
    init(_ hasRequiredCumulativeDaysOfUse: Bool) {
        self.hasMockRequiredDaysOfUse = hasRequiredCumulativeDaysOfUse
    }

    override var hasRequiredCumulativeDaysOfUse: Bool {
        return hasMockRequiredDaysOfUse
    }
}

// MARK: - CrashingMockLogger
class CrashingMockLogger: Logger {
    func setup(sendUsageData: Bool) {}
    func configure(crashManager: CrashManager) {}
    func copyLogsToDocuments() {}
    func logCustomError(error: Error) {}
    func deleteCachedLogFiles() {}

    var enableCrashOnLastLaunch = false
    var crashedLastLaunch: Bool {
        return enableCrashOnLastLaunch
    }
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
