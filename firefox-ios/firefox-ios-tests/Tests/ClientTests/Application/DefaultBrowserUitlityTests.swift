// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class DefaultBrowserUtilityTests: XCTestCase {
    var subject: DefaultBrowserUtility!
    var telemetryWrapper: MockTelemetryWrapper!
    var userDefaults: MockUserDefaults!
    var application: MockUIApplication!
    var locale: MockLocale!

    typealias DefaultKeys = DefaultBrowserUtility.UserDefaultsKey

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

    @MainActor
    func testFirstLaunchWithDMAUser() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectForTesting(region: "IE", setToDefault: true, isFirstRun: true)

        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.defaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.choiceScreenAcquisition))
        XCTAssertEqual(userDefaults.setCalledCount, 2)
    }

    @MainActor
    func testFirstLaunchWithNonDMAUser() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: true)

        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.defaultBrowser))
        XCTAssertFalse(telemetryWrapper.recordedObjects.contains(.choiceScreenAcquisition))
        XCTAssertEqual(userDefaults.setCalledCount, 1)
    }

    @MainActor
    func testSecondLaunchWithDMAUser() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectForTesting(region: "IT", setToDefault: true, isFirstRun: false)

        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.defaultBrowser))
        XCTAssertFalse(telemetryWrapper.recordedObjects.contains(.choiceScreenAcquisition))
        XCTAssertEqual(userDefaults.setCalledCount, 1)
    }

    @MainActor
    func testSecondLaunchWithNonDMAUser() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: false)

        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(telemetryWrapper.recordedObjects.contains(.defaultBrowser))
        XCTAssertFalse(telemetryWrapper.recordedObjects.contains(.choiceScreenAcquisition))
        XCTAssertEqual(userDefaults.setCalledCount, 1)
    }

    @MainActor
    func testMigration_ForNonUpdatingValues_WithNonDMAUser() {
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: false)
        subject.migrateDefaultBrowserStatusIfNeeded()

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))
    }

    @MainActor
    func testMigration_ForUpdatingValues_NonDMAUser_DefaultOldValueIsTrue_DefaultNewValueIsFalse() {
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))

        userDefaults.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)

        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: false)
        subject.migrateDefaultBrowserStatusIfNeeded()

        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))
    }

    @MainActor
    func testMigration_ForUpdatingValues_NonDMAUser_DefaultOldValueIsFalse_DefaultNewValueIsTrue() {
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))

        userDefaults.set(false, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)
        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: false)
        subject.migrateDefaultBrowserStatusIfNeeded()

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))
    }

    @MainActor
    func testMigration_ForNonUpdatingValues_WithDMAUser() {
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        setupSubjectForTesting(region: "IT", setToDefault: true, isFirstRun: false)
        subject.migrateDefaultBrowserStatusIfNeeded()

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))
    }

    @MainActor
    func testMigration_ForUpdatingValues_DMAUser_DefaultOldValueIsTrue_DefaultNewValueIsFalse() {
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))

        userDefaults.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)

        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        setupSubjectForTesting(region: "IT", setToDefault: true, isFirstRun: false)
        subject.migrateDefaultBrowserStatusIfNeeded()

        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))
    }

    @MainActor
    func testMigration_ForUpdatingValues_DMAUser_DefaultOldValueIsFalse_DefaultNewValueIsTrue() {
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))

        userDefaults.set(false, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)
        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        setupSubjectForTesting(region: "IT", setToDefault: true, isFirstRun: false)
        subject.migrateDefaultBrowserStatusIfNeeded()

        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.hasPerformedMigration))
    }

    @MainActor
    private func setupSubjectForTesting(
        region: String,
        setToDefault: Bool,
        isFirstRun: Bool
    ) {
        locale.localeRegionCode = region
        application.mockDefaultApplicationValue = setToDefault

        setupSubject()
        subject.processUserDefaultState(isFirstRun: isFirstRun)
    }

    @MainActor
    private func setupSubject() {
        subject = DefaultBrowserUtility(
            userDefault: userDefaults,
            telemetryWrapper: telemetryWrapper,
            locale: locale,
            application: application
        )
    }
}
