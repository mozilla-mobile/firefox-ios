// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Shared
import XCTest

@testable import Client

final class DefaultBrowserUtilityTests: XCTestCase {
    typealias DefaultKeys = DefaultBrowserUtility.UserDefaultsKey

    var subject: DefaultBrowserUtility!
    var mockGleanWrapper: MockGleanWrapper!
    var userDefaults: MockUserDefaults!
    var application: MockUIApplication!

    // For testing migration more legibly
    let deeplinkValueKey = DefaultKeys.isBrowserDefault
    let apiOrUserSetToDefaultKey = PrefsKeys.DidDismissDefaultBrowserMessage

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        userDefaults = MockUserDefaults()
        application = MockUIApplication()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        userDefaults = nil
        application = nil
        subject = nil
        super.tearDown()
    }

    @MainActor
    func testFirstLaunchWithDMAUser() throws {
        guard #available(iOS 18.2, *) else { return }

        let expectedBrowserEvent = GleanMetrics.App.defaultBrowser
        let expectedChoiceEvent = GleanMetrics.App.choiceScreenAcquisition
        setupSubjectForTesting(region: "IE", setToDefault: true, isFirstRun: true)

        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        let savedChoiceScreenMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[0] as? BooleanMetricType)
        let savedDefaultMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[1] as? BooleanMetricType)
        XCTAssert(savedDefaultMetric === expectedBrowserEvent)
        XCTAssert(savedChoiceScreenMetric === expectedChoiceEvent)

        XCTAssertEqual(userDefaults.setCalledCount, 5)
    }

    @MainActor
    func testFirstLaunchWithNonDMAUser() throws {
        guard #available(iOS 18.2, *) else { return }

        let expectedBrowserEvent = GleanMetrics.App.defaultBrowser
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: true)

        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        let savedDefaultMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? BooleanMetricType)
        XCTAssert(savedDefaultMetric === expectedBrowserEvent)

        XCTAssertEqual(userDefaults.setCalledCount, 4)
    }

    @MainActor
    func testSecondLaunchWithDMAUser() throws {
        guard #available(iOS 18.2, *) else { return }

        let expectedBrowserEvent = GleanMetrics.App.defaultBrowser
        setupSubjectForTesting(region: "IT", setToDefault: true, isFirstRun: false)

        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        let savedDefaultMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? BooleanMetricType)
        XCTAssert(savedDefaultMetric === expectedBrowserEvent)

        XCTAssertEqual(userDefaults.setCalledCount, 4)
    }

    @MainActor
    func testSecondLaunchWithNonDMAUser() throws {
        guard #available(iOS 18.2, *) else { return }

        let expectedBrowserEvent = GleanMetrics.App.defaultBrowser
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: false)

        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.isBrowserDefault))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.AppleConfirmedUserIsDefaultBrowser))

        let savedDefaultMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? BooleanMetricType)
        XCTAssert(savedDefaultMetric === expectedBrowserEvent)

        XCTAssertEqual(userDefaults.setCalledCount, 3)
    }

    // MARK: - Migration Flag Tests
    @MainActor
    func testMigration_migrationFlag_setDuringFirstLaunch() {
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.shouldNotPerformMigration))

        let isFirstRun = true
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.shouldNotPerformMigration))
    }

    @MainActor
    func testMigration_migrationFlag_setPostFirstLaunch() {
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.shouldNotPerformMigration))

        let isFirstRun = false
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.shouldNotPerformMigration))
    }

    @MainActor
    func testMigration_noMigrationHappensIfFlagIsSet() {
        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))
        XCTAssertFalse(userDefaults.bool(forKey: DefaultKeys.shouldNotPerformMigration))

        userDefaults.set(true, forKey: DefaultKeys.shouldNotPerformMigration)
        userDefaults.set(true, forKey: apiOrUserSetToDefaultKey)

        let isFirstRun = false
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertTrue(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))
        XCTAssertTrue(userDefaults.bool(forKey: DefaultKeys.shouldNotPerformMigration))
    }

    // MARK: - Migration Value Tests for DMA & NonDMA users
    @MainActor
    func testMigration_nonDMA_firstRun_isNotDefaultBrowser() {
        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))

        let isFirstRun = true
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertFalse(subject.isDefaultBrowser)
    }

    @MainActor
    func testMigration_nonDMA_postFirstRun_isNotDefaultBrowser() {
        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))

        let isFirstRun = false
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertFalse(subject.isDefaultBrowser)
    }

    @MainActor
    func testMigration_DMA_firstRun_isSetToDefaultBrowser() {
        guard #available(iOS 18.2, *) else { return }

        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))

        let isFirstRun = true
        setupSubjectForTesting(region: "IT", setToDefault: true, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertTrue(subject.isDefaultBrowser)
    }

    @MainActor
    func testMigration_DMA_postFirstRun_isDefaultBrowser() {
        guard #available(iOS 18.2, *) else { return }

        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))

        let isFirstRun = false
        setupSubjectForTesting(region: "IT", setToDefault: true, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertTrue(subject.isDefaultBrowser)
    }

    // MARK: - Migration tests for any type of user post first run
    @MainActor
    func testMigration_postFirstRun_isNotDefaultBrowser() {
        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))

        let isFirstRun = false
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertFalse(subject.isDefaultBrowser)
    }

    @MainActor
    func testMigration_postFirstRun_deeplinkIsTrue_isSetToDefaultBrowser() {
        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))

        let isFirstRun = false
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)

        userDefaults.set(true, forKey: deeplinkValueKey)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertTrue(subject.isDefaultBrowser)
    }

    @MainActor
    func testMigration_postFirstRun_apiOrUserSetToDefaultIsTrue_isSetToDefaultBrowser() {
        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))

        userDefaults.set(true, forKey: apiOrUserSetToDefaultKey)

        let isFirstRun = false
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertTrue(subject.isDefaultBrowser)
    }

    @MainActor
    func testMigration_postFirstRun_bothKeysAreTrue_isSetToDefaultBrowser() {
        XCTAssertFalse(userDefaults.bool(forKey: apiOrUserSetToDefaultKey))
        XCTAssertFalse(userDefaults.bool(forKey: deeplinkValueKey))

        userDefaults.set(true, forKey: apiOrUserSetToDefaultKey)
        userDefaults.set(true, forKey: deeplinkValueKey)

        let isFirstRun = false
        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: isFirstRun)
        subject.migrateDefaultBrowserStatusIfNeeded(isFirstRun: isFirstRun)

        XCTAssertTrue(subject.isDefaultBrowser)
    }

    // MARK: - API Error Tests
    @MainActor
    func testAPIError_recordsTelemetryWithErrorDetails() throws {
        guard #available(iOS 18.2, *) else { return }

        let expectedEvent = GleanMetrics.App.defaultBrowserApiError
        let retryDate = Date(timeIntervalSince1970: 1700000000)
        let lastProvidedDate = Date(timeIntervalSince1970: 1699000000)

        application.setupCategoryDefaultErrorWith(userInfo: [
            DefaultBrowserUtility.APIErrorDateKeys.retryDate: retryDate,
            DefaultBrowserUtility.APIErrorDateKeys.lastProvidedDate: lastProvidedDate
        ])

        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: true)

        typealias EventExtra = GleanMetrics.App.DefaultBrowserApiErrorExtra
        let savedEvent = try XCTUnwrap(mockGleanWrapper.savedEvents.last as? EventMetricType<EventExtra>)
        let extras = try XCTUnwrap(mockGleanWrapper.savedExtras.last as? EventExtra)

        XCTAssert(savedEvent === expectedEvent)
        XCTAssertEqual(extras.apiQueryCount, 1)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let retryDateString = try XCTUnwrap(extras.retryDate)
        let savedRetryDate = try XCTUnwrap(formatter.date(from: retryDateString))
        XCTAssertEqual(savedRetryDate, retryDate)

        let lastProvidedDateString = try XCTUnwrap(extras.lastProvidedDate)
        let savedLastProvidedDate = try XCTUnwrap(formatter.date(from: lastProvidedDateString))
        XCTAssertEqual(savedLastProvidedDate, lastProvidedDate)
    }

    @MainActor
    func testAPIError_savesDatesinUserDefaults() {
        guard #available(iOS 18.2, *) else { return }

        let retryDate = Date(timeIntervalSince1970: 1700000000)
        let lastProvidedDate = Date(timeIntervalSince1970: 1699000000)

        application.setupCategoryDefaultErrorWith(userInfo: [
            DefaultBrowserUtility.APIErrorDateKeys.retryDate: retryDate,
            DefaultBrowserUtility.APIErrorDateKeys.lastProvidedDate: lastProvidedDate
        ])

        setupSubjectForTesting(region: "US", setToDefault: false, isFirstRun: true)

        let savedRetryDate = userDefaults.object(
            forKey: DefaultBrowserUtility.APIErrorDateKeys.retryDate
        ) as? Date
        let savedLastProvidedDate = userDefaults.object(
            forKey: DefaultBrowserUtility.APIErrorDateKeys.lastProvidedDate
        ) as? Date

        XCTAssertEqual(savedRetryDate, retryDate)
        XCTAssertEqual(savedLastProvidedDate, lastProvidedDate)
    }

    // MARK: - Default Browser Set Date Tests
    @MainActor
    func testDefaultBrowserSetDate_savedWhenSettingToTrue() {
        setupSubjectWithMocks()

        XCTAssertNil(userDefaults.object(forKey: DefaultKeys.defaultBrowserSetDate))
        subject.isDefaultBrowser = true

        XCTAssertNotNil(userDefaults.object(forKey: DefaultKeys.defaultBrowserSetDate))
    }

    @MainActor
    func testDefaultBrowserSetDate_notUpdatedWhenSettingToFalse() {
        setupSubjectWithMocks()

        subject.isDefaultBrowser = true
        let originalDate = userDefaults.object(forKey: DefaultKeys.defaultBrowserSetDate) as? Date

        subject.isDefaultBrowser = false

        let currentDate = userDefaults.object(forKey: DefaultKeys.defaultBrowserSetDate) as? Date
        XCTAssertEqual(currentDate, originalDate)
    }

    @MainActor
    func testDefaultBrowserSetDate_updatedWhenSettingToTrueAgain() {
        setupSubjectWithMocks()

        subject.isDefaultBrowser = true
        let originalDate = userDefaults.object(forKey: DefaultKeys.defaultBrowserSetDate) as? Date

        // Wait a tiny bit to ensure new date is different
        Thread.sleep(forTimeInterval: 0.01)

        subject.isDefaultBrowser = true
        let newDate = userDefaults.object(forKey: DefaultKeys.defaultBrowserSetDate) as? Date

        XCTAssertNotNil(newDate)
        XCTAssertGreaterThan(newDate!, originalDate!)
    }

    // MARK: - API Last Use Date Tests
    @MainActor
    func testAppleAPILastUseDate_savedWhenAPIIsCalled_firstRun() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        XCTAssertNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))

        subject.processUserDefaultState(isFirstRun: true)

        XCTAssertNotNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))
    }

    @MainActor
    func testAppleAPILastUseDate_savedWhenAPIIsCalled_subsequentRuns() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        XCTAssertNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))

        subject.processUserDefaultState(isFirstRun: false)

        XCTAssertNotNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))
    }

    // MARK: - Status Expiration Tests (via processUserDefaultState)
    @MainActor
    func testProcessUserDefaultState_expiresStatusWhenOlderThanOneMonth() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = false

        // Set up: was default 2 months ago
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.defaultBrowserSetDate)

        subject.processUserDefaultState(isFirstRun: false)

        // Status should be expired to false (regardless of API result)
        XCTAssertFalse(subject.isDefaultBrowser)
    }

    @MainActor
    func testProcessUserDefaultState_doesNotExpireStatusWhenRecent() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        // Set up: was default recently
        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)
        userDefaults.set(Date(), forKey: DefaultKeys.defaultBrowserSetDate)

        subject.processUserDefaultState(isFirstRun: false)

        XCTAssertTrue(subject.isDefaultBrowser)
    }

    // MARK: - API Query Gating Tests (via processUserDefaultState)
    @MainActor
    func testProcessUserDefaultState_callsAPIWhenNeverUsedBefore() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        // No prior API use date
        XCTAssertNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))

        subject.processUserDefaultState(isFirstRun: false)

        // API should have been called (last use date set)
        XCTAssertNotNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))
    }

    @MainActor
    func testProcessUserDefaultState_skipsAPIWhenNotPastRetryDate() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        XCTAssertNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))

        // Set up: used API before, retry date in future
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        userDefaults.set(yesterday, forKey: DefaultKeys.appleAPILastUseDate)
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        userDefaults.set(futureDate, forKey: DefaultBrowserUtility.APIErrorDateKeys.retryDate)

        subject.processUserDefaultState(isFirstRun: false)

        // API should NOT have been called (last use date unchanged)
        let lastUseDate = userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate) as? Date
        XCTAssertEqual(lastUseDate, yesterday)
    }

    @MainActor
    func testProcessUserDefaultState_skipsAPIWhenSetAsDefaultInLastMonth() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        // Set up: used API before, set as default recently
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        userDefaults.set(yesterday, forKey: DefaultKeys.appleAPILastUseDate)
        userDefaults.set(Date(), forKey: DefaultKeys.defaultBrowserSetDate)
        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)

        subject.processUserDefaultState(isFirstRun: false)

        // API should NOT have been called (last use date unchanged)
        let lastUseDate = userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate) as? Date
        XCTAssertEqual(lastUseDate, yesterday)
    }

    @MainActor
    func testProcessUserDefaultState_callsAPIWhenThreeMonthsSinceLastUse() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        // Set up: used API 4 months ago, set as default 2 months ago
        let fourMonthsAgo = Calendar.current.date(byAdding: .month, value: -4, to: Date())!
        userDefaults.set(fourMonthsAgo, forKey: DefaultKeys.appleAPILastUseDate)
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.defaultBrowserSetDate)

        subject.processUserDefaultState(isFirstRun: false)

        // API should have been called (last use date updated)
        let lastUseDate = userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate) as? Date
        XCTAssertNotEqual(lastUseDate, fourMonthsAgo)
    }

    @MainActor
    func testProcessUserDefaultState_threeMonthRefreshTakesPriorityOverRecentDefault() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        // Set up: used API 4 months ago, but set as default only 2 weeks ago
        // The 3-month refresh should take priority over "set as default recently"
        let fourMonthsAgo = Calendar.current.date(byAdding: .month, value: -4, to: Date())!
        userDefaults.set(fourMonthsAgo, forKey: DefaultKeys.appleAPILastUseDate)
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        userDefaults.set(twoWeeksAgo, forKey: DefaultKeys.defaultBrowserSetDate)
        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)

        subject.processUserDefaultState(isFirstRun: false)

        // API should have been called (3-month refresh takes priority)
        let lastUseDate = userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate) as? Date
        XCTAssertNotEqual(lastUseDate, fourMonthsAgo)
    }

    @MainActor
    func testProcessUserDefaultState_skipsAPIWhenLessThanThreeMonthsSinceLastUse() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        // Set up: used API 2 months ago, set as default 2 months ago
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.appleAPILastUseDate)
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.defaultBrowserSetDate)

        subject.processUserDefaultState(isFirstRun: false)

        // API should NOT have been called (last use date unchanged)
        let lastUseDate = userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate) as? Date
        XCTAssertEqual(lastUseDate, twoMonthsAgo)
    }

    // MARK: - Helpers
    @MainActor
    private func setupSubjectWithMocks() {
        let locale = MockLocaleProvider(localeRegionCode: "US")
        setupSubject(with: locale)
    }

    @MainActor
    private func setupSubjectForTesting(
        region: String,
        setToDefault: Bool,
        isFirstRun: Bool
    ) {
        let locale = MockLocaleProvider(localeRegionCode: region)
        application.mockDefaultApplicationValue = setToDefault

        setupSubject(with: locale)
        subject.processUserDefaultState(isFirstRun: isFirstRun)
    }

    @MainActor
    private func setupSubject(with locale: LocaleProvider) {
        subject = DefaultBrowserUtility(
            userDefault: userDefaults,
            telemetry: DefaultBrowserUtilityTelemetry(gleanWrapper: mockGleanWrapper),
            locale: locale,
            application: application
        )
    }
}
