// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest
import Shared
import Common

class StartAtHomeHelperTests: XCTestCase {
    private var helper: StartAtHomeHelper!
    private var profile: MockProfile!
    private var tabManager: TabManager!

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        tabManager = TabManagerImplementation(profile: profile,
                                              uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))

        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        tabManager = nil
        helper = nil

        DependencyHelperMock().reset()
    }

    func testShouldNotSkipStartAtHome() throws {
        setupHelper()
        let shouldSkip = helper.shouldSkipStartHome

        XCTAssertFalse(shouldSkip, "Should not skip StartAtHome")
    }

    func testShouldSkipStartAtHome_RestoringTabs() throws {
        setupHelper(isRestoringTabs: true)
        let shouldSkip = helper.shouldSkipStartHome
        XCTAssertTrue(shouldSkip, "Expected to skip because is restoring tabs")
    }

    func test_shouldSkipStartAtHome_openedFromExternalSource() {
        let mockAppSessionManager = MockAppSessionManager()
        mockAppSessionManager.launchSessionProvider.openedFromExternalSource = true

        setupHelper(appSessionManager: mockAppSessionManager)
        let shouldSkip = helper.shouldSkipStartHome

        XCTAssert(shouldSkip, "Expected to skip because the app was opened from an external source.")
    }

    func testNotShouldStartAtHome_AfterFourHours() {
        setupHelper()
        setupLastActiveTimeStamp(value: -3)
        XCTAssertFalse(helper.shouldStartAtHome(), "Expected to fail for less than 4 hours")
    }

    func testShouldStartAtHome_AfterFourHours() {
        setupHelper()
        setupLastActiveTimeStamp(value: -5)
        XCTAssertTrue(helper.shouldStartAtHome(), "Expected to pass for more than 4 hours")
    }

    func testNotShouldStartAtHome_Always() {
        setupHelper()
        helper.startAtHomeSetting = .always
        setupLastActiveTimeStamp(value: -3, dateComponents: .second)
        XCTAssertFalse(helper.shouldStartAtHome(), "Expected to fail for more than 5 seconds")
    }

    func testShouldStartAtHome_Always() {
        setupHelper()
        helper.startAtHomeSetting = .always
        setupLastActiveTimeStamp(value: -6, dateComponents: .second)
        XCTAssertTrue(helper.shouldStartAtHome(), "Expected to pass for more than 5 seconds")
    }

    func testShouldStartAtHome_Disabled() {
        setupHelper()
        helper.startAtHomeSetting = .disabled
        XCTAssertFalse(helper.shouldStartAtHome(), "Expected to fail for disabled state")
    }

    func testScanForExistingHomeTab_ForEmptyTabs() {
        setupHelper()
        let homeTab = helper.scanForExistingHomeTab(in: [], with: profile.prefs)
        XCTAssertNil(homeTab, "Expected to fail for disabled state")
    }

    func testScanForExistingHomeTab_WithHomePage() {
        setupHelper()

        // Create home tab
        let url = URL(string: "internal://local/about/home")
        let urlRequest = URLRequest(url: url!)
        let tab = tabManager.addTab(urlRequest)

        let homeTab = helper.scanForExistingHomeTab(in: [tab], with: profile.prefs)
        XCTAssertNotNil(homeTab, "Expected to have a existing tab")
    }

    func testScanForExistingHomeTab_WithoutHomePage() {
        setupHelper()

        // Create tab different than home
        let url = URL(string: "https://www.mozilla.org")
        let urlRequest = URLRequest(url: url!)
        let tab = tabManager.addTab(urlRequest)

        let homeTab = helper.scanForExistingHomeTab(in: [tab], with: profile.prefs)
        XCTAssertNil(homeTab, "Expected to fail for disabled state")
    }

    // MARK: - Private
    private func setupHelper(
        appSessionManager: MockAppSessionManager = MockAppSessionManager(),
        isRestoringTabs: Bool = false
    ) {
        helper = StartAtHomeHelper(
            appSessionManager: appSessionManager,
            prefs: profile.prefs,
            isRestoringTabs: isRestoringTabs,
            isRunningUITest: false
        )

        helper.startAtHomeSetting = .afterFourHours
    }

    private func setupLastActiveTimeStamp(value: Int, dateComponents: Calendar.Component = .hour) {
        let currentDate = Date()
        var modifiedDate = currentDate

        if dateComponents == .second {
            modifiedDate = Calendar.current.date(byAdding: .second, value: value, to: currentDate)!
        } else {
            modifiedDate = Calendar.current.date(byAdding: .hour, value: value, to: currentDate)!
        }
        UserDefaults.standard.setValue(modifiedDate, forKey: "LastActiveTimestamp")
    }
}
