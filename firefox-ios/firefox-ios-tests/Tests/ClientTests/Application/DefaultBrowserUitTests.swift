// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class DefaultBrowserUitTests: XCTestCase {
    var subject: DefaultBrowserUtil!
    var telemetryWrapper: MockTelemetryWrapper!
    var userDefaults: MockUserDefaults!
    var application: MockUIApplication!
    var locale: MockLocale!

    override func setUp() {
        super.setUp()
        telemetryWrapper = MockTelemetryWrapper()
        userDefaults = MockUserDefaults()
        locale = MockLocale()
        application = MockUIApplication()
    }

    override func tearDown() {
        telemetryWrapper = nil
        userDefaults = nil
        locale = nil
        application = nil
        subject = nil
        super.tearDown()
    }

    func testFirstLaunchWithDMAUser() {
        guard #available(iOS 18.2, *) else { return }

        locale.localeRegionCode = "IE"
        application.mockDefaultApplicationValue = true

        setupSubject()
        subject.processUserDefaultState(isFirstRun: true)

        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.defaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.choiceScreenAcquisition))
        XCTAssertEqual(userDefaults.setCalledCount, 2)
    }

    func testFirstLaunchWithNonDMAUser() {
        guard #available(iOS 18.2, *) else { return }

        locale.localeRegionCode = "US"
        application.mockDefaultApplicationValue = false

        setupSubject()
        subject.processUserDefaultState(isFirstRun: true)

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.defaultBrowser))
        XCTAssertFalse(telemetryWrapper.recordedObjects.contains(.choiceScreenAcquisition))
        XCTAssertEqual(userDefaults.setCalledCount, 1)
    }

    func testSecondLaunchWithDMAUser() {
        guard #available(iOS 18.2, *) else { return }

        locale.localeRegionCode = "IT"
        application.mockDefaultApplicationValue = true

        setupSubject()
        subject.processUserDefaultState(isFirstRun: false)

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.defaultBrowser))
        XCTAssertFalse(telemetryWrapper.recordedObjects.contains(.choiceScreenAcquisition))
        XCTAssertEqual(userDefaults.setCalledCount, 1)
    }

    func testSecondLaunchWithNonDMAUser() {
        guard #available(iOS 18.2, *) else { return }

        locale.localeRegionCode = "US"
        application.mockDefaultApplicationValue = false

        setupSubject()
        subject.processUserDefaultState(isFirstRun: false)

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.defaultBrowser))
        XCTAssertFalse(telemetryWrapper.recordedObjects.contains(.choiceScreenAcquisition))
        XCTAssertEqual(userDefaults.setCalledCount, 1)
    }

    private func setupSubject() {
        subject = DefaultBrowserUtil(userDefault: userDefaults,
                                     telemetryWrapper: telemetryWrapper,
                                     locale: locale,
                                     application: application)
    }
}
