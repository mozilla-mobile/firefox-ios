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

        let savedDefaultMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? BooleanMetricType)
        let savedChoiceScreenMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[1] as? BooleanMetricType)
        XCTAssert(savedDefaultMetric === expectedBrowserEvent)
        XCTAssert(savedChoiceScreenMetric === expectedChoiceEvent)

        // Original 3 + 1 (defaultBrowserAPILastUseDate) + 1 (defaultBrowserSetDate)
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

        // Original 3 + 1 (defaultBrowserAPILastUseDate)
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

        // Original 2 + 1 (defaultBrowserAPILastUseDate) + 1 (defaultBrowserSetDate)
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

        // Original 2 + 1 (defaultBrowserAPILastUseDate)
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
    func testAppleAPILastUseDate_savedWhenAPIIsCalled() {
        guard #available(iOS 18.2, *) else { return }

        setupSubjectWithMocks()
        application.mockDefaultApplicationValue = true

        XCTAssertNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))

        subject.processUserDefaultState(isFirstRun: true)

        XCTAssertNotNil(userDefaults.object(forKey: DefaultKeys.appleAPILastUseDate))
    }

    // MARK: - wasSetAsDefaultWithinLastMonth Tests
    @MainActor
    func testWasSetAsDefaultWithinLastMonth_returnsFalseWhenNoDate() {
        setupSubjectWithMocks()

        XCTAssertFalse(subject.wasSetAsDefaultWithinLastMonth())
    }

    @MainActor
    func testWasSetAsDefaultWithinLastMonth_returnsTrueWhenRecent() {
        setupSubjectWithMocks()

        userDefaults.set(Date(), forKey: DefaultKeys.defaultBrowserSetDate)

        XCTAssertTrue(subject.wasSetAsDefaultWithinLastMonth())
    }

    @MainActor
    func testWasSetAsDefaultWithinLastMonth_returnsFalseWhenOld() {
        setupSubjectWithMocks()

        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.defaultBrowserSetDate)

        XCTAssertFalse(subject.wasSetAsDefaultWithinLastMonth())
    }

    // MARK: - hasBeenAtLeastThreeMonthsSinceLastAPIUse Tests
    @MainActor
    func testHasBeenAtLeastThreeMonthsSinceLastAPIUse_returnsTrueWhenNoDate() {
        setupSubjectWithMocks()

        XCTAssertTrue(subject.hasBeenAtLeastThreeMonthsSinceLastAPIUse())
    }

    @MainActor
    func testHasBeenAtLeastThreeMonthsSinceLastAPIUse_returnsFalseWhenRecent() {
        setupSubjectWithMocks()

        userDefaults.set(Date(), forKey: DefaultKeys.appleAPILastUseDate)

        XCTAssertFalse(subject.hasBeenAtLeastThreeMonthsSinceLastAPIUse())
    }

    @MainActor
    func testHasBeenAtLeastThreeMonthsSinceLastAPIUse_returnsTrueWhenOld() {
        setupSubjectWithMocks()

        let fourMonthsAgo = Calendar.current.date(byAdding: .month, value: -4, to: Date())!
        userDefaults.set(fourMonthsAgo, forKey: DefaultKeys.appleAPILastUseDate)

        XCTAssertTrue(subject.hasBeenAtLeastThreeMonthsSinceLastAPIUse())
    }

    // MARK: - isPastRetryDate Tests
    @MainActor
    func testIsPastRetryDate_returnsTrueWhenNoRetryDate() {
        setupSubjectWithMocks()

        XCTAssertTrue(subject.isPastRetryDate())
    }

    @MainActor
    func testIsPastRetryDate_returnsFalseWhenRetryDateInFuture() {
        setupSubjectWithMocks()

        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        userDefaults.set(futureDate, forKey: DefaultBrowserUtility.APIErrorDateKeys.retryDate)

        XCTAssertFalse(subject.isPastRetryDate())
    }

    @MainActor
    func testIsPastRetryDate_returnsTrueWhenRetryDateInPast() {
        setupSubjectWithMocks()

        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        userDefaults.set(pastDate, forKey: DefaultBrowserUtility.APIErrorDateKeys.retryDate)

        XCTAssertTrue(subject.isPastRetryDate())
    }

    // MARK: - expireDefaultStatusIfStale Tests
    @MainActor
    func testExpireDefaultStatusIfStale_expiresWhenOlderThanOneMonth() {
        setupSubjectWithMocks()

        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.defaultBrowserSetDate)

        subject.expireDefaultStatusIfStale()

        XCTAssertFalse(subject.isDefaultBrowser)
    }

    @MainActor
    func testExpireDefaultStatusIfStale_doesNotExpireWhenRecent() {
        setupSubjectWithMocks()

        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)
        userDefaults.set(Date(), forKey: DefaultKeys.defaultBrowserSetDate)

        subject.expireDefaultStatusIfStale()

        XCTAssertTrue(subject.isDefaultBrowser)
    }

    @MainActor
    func testExpireDefaultStatusIfStale_preservesSetDateWhenExpiring() {
        setupSubjectWithMocks()

        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        userDefaults.set(true, forKey: DefaultKeys.isBrowserDefault)
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.defaultBrowserSetDate)

        subject.expireDefaultStatusIfStale()

        // The date should be preserved (not cleared or updated)
        let currentDate = userDefaults.object(forKey: DefaultKeys.defaultBrowserSetDate) as? Date
        XCTAssertEqual(currentDate, twoMonthsAgo)
    }

    // MARK: - shouldQueryAppleDefaultBrowserAPI Tests
    @MainActor
    func testShouldQueryAppleDefaultBrowserAPI_returnsTrueWhenNeverUsedBefore() {
        setupSubjectWithMocks()

        XCTAssertTrue(subject.shouldQueryAppleDefaultBrowserAPI())
    }

    @MainActor
    func testShouldQueryAppleDefaultBrowserAPI_returnsFalseWhenNotPastRetryDate() {
        setupSubjectWithMocks()

        // Set last use date so we've used API before
        userDefaults.set(Date(), forKey: DefaultKeys.appleAPILastUseDate)
        // Set retry date in the future
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        userDefaults.set(futureDate, forKey: DefaultBrowserUtility.APIErrorDateKeys.retryDate)

        XCTAssertFalse(subject.shouldQueryAppleDefaultBrowserAPI())
    }

    @MainActor
    func testShouldQueryAppleDefaultBrowserAPI_returnsFalseWhenSetAsDefaultInLastMonth() {
        setupSubjectWithMocks()

        // Set last use date so we've used API before
        userDefaults.set(Date(), forKey: DefaultKeys.appleAPILastUseDate)
        // Set as default recently
        userDefaults.set(Date(), forKey: DefaultKeys.defaultBrowserSetDate)
        // No retry date, so we're past it

        XCTAssertFalse(subject.shouldQueryAppleDefaultBrowserAPI())
    }

    @MainActor
    func testShouldQueryAppleDefaultBrowserAPI_returnsTrueWhenThreeMonthsSinceLastUse() {
        setupSubjectWithMocks()

        // Set last use date to 4 months ago
        let fourMonthsAgo = Calendar.current.date(byAdding: .month, value: -4, to: Date())!
        userDefaults.set(fourMonthsAgo, forKey: DefaultKeys.appleAPILastUseDate)
        // Set default date to 2 months ago (not within last month)
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.defaultBrowserSetDate)
        // No retry date, so we're past it

        XCTAssertTrue(subject.shouldQueryAppleDefaultBrowserAPI())
    }

    @MainActor
    func testShouldQueryAppleDefaultBrowserAPI_returnsFalseWhenLessThanThreeMonthsSinceLastUse() {
        setupSubjectWithMocks()

        // Set last use date to 2 months ago (less than 3 months)
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.appleAPILastUseDate)
        // Set default date to 2 months ago (not within last month)
        userDefaults.set(twoMonthsAgo, forKey: DefaultKeys.defaultBrowserSetDate)
        // No retry date, so we're past it

        XCTAssertFalse(subject.shouldQueryAppleDefaultBrowserAPI())
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
