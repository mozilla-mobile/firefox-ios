// swiftlint:disable force_try
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class UserTests: XCTestCase {
    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    func testFirstTime() {
        let expect = expectation(description: "")
        XCTAssertTrue(User.shared.firstTime)
        let analyticsId = User.shared.analyticsId
        User.shared.firstTime = false
        User.queue.async {
            let user = User()
            XCTAssertEqual(analyticsId, user.analyticsId)
            XCTAssertFalse(user.firstTime)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testInstall() {
        let date = Date()
        try? FileManager.default.removeItem(at: FileManager.user)
        XCTAssertGreaterThanOrEqual(Int(User().install.timeIntervalSince1970), Int(date.timeIntervalSince1970))
    }

    func testInstallSavesAfterFirst() {
        let expect = expectation(description: "")
        let user = User()
        User.queue.async {
            XCTAssertEqual(Int(user.install.timeIntervalSince1970), Int(User().install.timeIntervalSince1970))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testNotSavingOnLoad() {
        let expect = expectation(description: "")
        var user = User()
        user.firstTime = false
        User.shared = user
        User.queue.async {
            user = User()
            try! FileManager.default.removeItem(at: FileManager.user)
            XCTAssertFalse(user.firstTime)
            User.queue.async {
                XCTAssertNotNil(user)
                DispatchQueue.main.async {
                    XCTAssertFalse(FileManager.default.fileExists(atPath: FileManager.user.path))
                    expect.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testAnalyticsId() {
        let expect = expectation(description: "")
        let id = UUID()
        XCTAssertNotEqual(id, User.shared.analyticsId)
        User.shared.analyticsId = id
        User.queue.async {
            let user = User()
            XCTAssertEqual(id, user.analyticsId)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testTreeCount() {
        let expect = expectation(description: "")
        User.shared.searchCount = 123
        User.queue.async {
            let user = User()
            XCTAssertEqual(123, user.searchCount)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testAdultFilter() {
        let expect = expectation(description: "")
        User.shared.adultFilter = .off
        User.queue.async {
            let user = User()
            XCTAssertEqual(.off, user.adultFilter)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testMarketCode() {
        let expect = expectation(description: "")
        User.shared.marketCode = .ar_sa
        User.queue.async {
            let user = User()
            XCTAssertEqual(.ar_sa, user.marketCode)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testAutoComplete() {
        let expect = expectation(description: "")
        User.shared.autoComplete = false
        User.queue.async {
            let user = User()
            XCTAssertFalse(user.autoComplete)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testState() {
        let expect = expectation(description: "")
        User.shared.state["lorem"] = "hello"
        User.queue.async {
            let user = User()
            XCTAssertEqual("hello", user.state["lorem"])
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testId() {
        let expect = expectation(description: "")
        User.shared.id = "hello world"
        User.queue.async {
            let user = User()
            XCTAssertEqual("hello world", user.id)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testPersonalized() {
        let expect = expectation(description: "")
        User.shared.personalized = true
        User.queue.async {
            let user = User()
            XCTAssertEqual(true, user.personalized)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSendAnonymousUsageData() {
        let expect = expectation(description: "")
        User.shared.sendAnonymousUsageData = false
        User.queue.async {
            let user = User()
            XCTAssertEqual(false, user.personalized)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSendAnonymousUsageDataDefaultsToTrue() {
        let user = User()
        XCTAssertEqual(true, user.sendAnonymousUsageData)
    }

    func testMigrated() {
        let expect = expectation(description: "")
        XCTAssert(User.shared.migrated == false)
        User.shared.migrated = true
        User.queue.async {
            let user = User()
            XCTAssertEqual(true, user.migrated)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testNews() {
        let expect = expectation(description: "")
        XCTAssertEqual(.distantPast, User.shared.news)
        User.shared.news = Date()
        User.queue.async {
            let user = User()
            XCTAssertNotNil(user.news)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testShowTopSites() {
        let expect = expectation(description: "")
        XCTAssertEqual(true, User.shared.showTopSites)
        User.shared.showTopSites = false
        User.queue.async {
            let user = User()
            XCTAssertEqual(false, user.showTopSites)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testTopSitesRows() {
        let expect = expectation(description: "")
        XCTAssertEqual(4, User.shared.topSitesRows)
        User.shared.topSitesRows = 2
        User.queue.async {
            let user = User()
            XCTAssertEqual(2, user.topSitesRows)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testShowClimateImpact() {
        let expect = expectation(description: "")
        XCTAssertEqual(true, User.shared.showClimateImpact)
        User.shared.showClimateImpact = false
        User.queue.async {
            let user = User()
            XCTAssertEqual(false, user.showClimateImpact)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testShowEcosiaNews() {
        let expect = expectation(description: "")
        XCTAssertEqual(true, User.shared.showEcosiaNews)
        User.shared.showEcosiaNews = false
        User.queue.async {
            let user = User()
            XCTAssertEqual(false, user.showEcosiaNews)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testWhatsNewItemsVersions() {
        let expect = expectation(description: "")
        XCTAssertTrue(User.shared.whatsNewItemsVersionsShown.isEmpty)
        User.shared.whatsNewItemsVersionsShown.formUnion(["test", "test1", "test"])
        User.queue.async {
            let user = User()
            XCTAssertEqual(user.whatsNewItemsVersionsShown, ["test", "test1"])
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testShowsReferralSpotlight() {
        let expect = expectation(description: "")
        XCTAssertFalse(User.shared.showsReferralSpotlight)

        // set install to 4 days ago
        User.shared.install = Calendar.current.date(byAdding: .day, value: -4, to: .init())!

        User.queue.async {
            let user = User()
            XCTAssertTrue(user.showsReferralSpotlight)

            User.shared.hideReferralSpotlight()
            User.queue.async {
                let user = User()
                XCTAssertFalse(user.showsReferralSpotlight)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testShowsInactiveTabsTooltip() {
        let expect = expectation(description: "")
        XCTAssertTrue(User.shared.showsInactiveTabsTooltip)

        User.queue.async {
            let user = User()
            XCTAssertTrue(user.showsInactiveTabsTooltip)

            User.shared.hideInactiveTabsTooltip()
            User.queue.async {
                let user = User()
                XCTAssertFalse(user.showsInactiveTabsTooltip)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testShowsBookmarksImportExportTooltip() {
        let expect = expectation(description: "")
        User.shared.state = [:]

        XCTAssertTrue(User.shared.showsBookmarksImportExportTooltip)

        User.queue.async {
            let user = User()
            XCTAssertTrue(user.showsBookmarksImportExportTooltip)

            User.shared.hideBookmarksImportExportTooltip()
            User.queue.async {
                let user = User()
                XCTAssertFalse(user.showsBookmarksImportExportTooltip)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testCookieCounterConsent() {
        let expect = expectation(description: "")
        User.queue.async {
            let user = User()
            XCTAssertNil(user.cookieConsentValue)
            User.shared.cookieConsentValue = "eamp"
            User.queue.async {
                let user = User()
                XCTAssertEqual("eamp", user.cookieConsentValue)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testSearchSettingChangeNotifiaction() {
        let expect = expectation(description: "")
        var count = 0

        NotificationCenter.default.addObserver(forName: .searchSettingsChanged, object: nil, queue: .main) { _ in

            count += 1

            if count == 4 {
                expect.fulfill()
            }
        }

        User.shared.personalized = !User.shared.personalized
        User.shared.marketCode = .en_ww
        User.shared.autoComplete = !User.shared.autoComplete
        User.shared.adultFilter = .off

        wait(for: [expect], timeout: 1)
    }

    func testAnalyticsUserState() {
        let expect = expectation(description: "")
        User.shared.analyticsUserState = User.AnalyticsStateContext()
        User.queue.async {
            let user = User()
            XCTAssertEqual(User.PushNotificationState.notDetermined, user.analyticsUserState.pushNotificationState)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
// swiftlint:enable force_try
