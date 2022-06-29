// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class TelemetryWrapperTests: XCTestCase {

    override func setUp() {
        super.setUp()

        Glean.shared.resetGlean(clearStores: true)
        Glean.shared.enableTestingMode()
    }

    // MARK: - Top Site

    func test_topSiteTileWithExtras_GleanIsCalled() {
        let topSitePositionKey = TelemetryWrapper.EventExtraKey.topSitePosition.rawValue
        let topSiteTileTypeKey = TelemetryWrapper.EventExtraKey.topSiteTileType.rawValue
        let extras = [topSitePositionKey: "\(1)", topSiteTileTypeKey: "history-based"]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .topSiteTile, value: nil, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.TopSites.tilePressed)
    }

    func test_topSiteTileWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .topSiteTile, value: nil)
        XCTAssertFalse(GleanMetrics.TopSites.tilePressed.testHasValue())
    }

    func test_topSiteContextualMenu_GleanIsCalled() {
        let extras = [TelemetryWrapper.EventExtraKey.contextualMenuType.rawValue: HomepageContextMenuHelper.ContextualActionType.settings.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .topSiteContextualMenu, value: nil, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.TopSites.contextualMenu)
    }

    func test_topSiteContextualMenuWithoutExtra_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .topSiteContextualMenu, value: nil, extras: nil)
        XCTAssertFalse(GleanMetrics.TopSites.contextualMenu.testHasValue())
    }

    // MARK: - Preferences

    func test_preferencesWithExtras_GleanIsCalled() {
        let extras: [String: Any] = [TelemetryWrapper.EventExtraKey.preference.rawValue: "ETP-strength",
                                      TelemetryWrapper.EventExtraKey.preferenceChanged.rawValue: BlockingStrength.strict.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .change, object: .setting, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Preferences.changed)
    }

    func test_preferencesWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .change, object: .setting)
        XCTAssertFalse(GleanMetrics.Preferences.changed.testHasValue())
    }

    // MARK: - Firefox Home Page

    func test_recentlySavedBookmarkViewWithExtras_GleanIsCalled() {
        let extras: [String: Any] = [TelemetryWrapper.EventObject.recentlySavedBookmarkImpressions.rawValue: "\([].count)"]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .recentlySavedBookmarkItemView, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.FirefoxHomePage.recentlySavedBookmarkView)
    }

    func test_recentlySavedBookmarkViewWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .recentlySavedBookmarkItemView)
        XCTAssertFalse(GleanMetrics.FirefoxHomePage.recentlySavedBookmarkView.testHasValue())
    }

    func test_recentlySavedReadingListViewViewWithExtras_GleanIsCalled() {
        let extras: [String: Any] = [TelemetryWrapper.EventObject.recentlySavedReadingItemImpressions.rawValue: "\([].count)"]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .recentlySavedReadingListView, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.FirefoxHomePage.readingListView)
    }

    func test_recentlySavedReadingListViewWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .recentlySavedReadingListView)
        XCTAssertFalse(GleanMetrics.FirefoxHomePage.readingListView.testHasValue())
    }

    func test_firefoxHomePageAddView_GleanIsCalled() {
        let extras = [TelemetryWrapper.EventExtraKey.fxHomepageOrigin.rawValue: TelemetryWrapper.EventValue.fxHomepageOriginZeroSearch.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .firefoxHomepage, value: .fxHomepageOrigin, extras: extras)

        testLabeledMetricSuccess(metric: GleanMetrics.FirefoxHomePage.firefoxHomepageOrigin)
    }

    // MARK: - CFR Analytics

    func test_contextualHintDismissButton_GleanIsCalled() {
        let extra = [TelemetryWrapper.EventExtraKey.cfrType.rawValue: ContextualHintViewType.toolbarLocation.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .contextualHint, value: .dismissCFRFromButton, extras: extra)

        testEventMetricRecordingSuccess(metric: GleanMetrics.CfrAnalytics.dismissCfrFromButton)
    }

    func test_contextualHintDismissButtonWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .contextualHint, value: .dismissCFRFromButton)
        XCTAssertFalse(GleanMetrics.CfrAnalytics.dismissCfrFromButton.testHasValue())
    }

    func test_contextualHintDismissOutsideTap_GleanIsCalled() {
        let extra = [TelemetryWrapper.EventExtraKey.cfrType.rawValue: ContextualHintViewType.toolbarLocation.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .contextualHint, value: .dismissCFRFromOutsideTap, extras: extra)

        testEventMetricRecordingSuccess(metric: GleanMetrics.CfrAnalytics.dismissCfrFromOutsideTap)
    }

    func test_contextualHintDismissOutsideTapWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .contextualHint, value: .dismissCFRFromOutsideTap)
        XCTAssertFalse(GleanMetrics.CfrAnalytics.dismissCfrFromOutsideTap.testHasValue())
    }

    func test_contextualHintPressAction_GleanIsCalled() {
        let extra = [TelemetryWrapper.EventExtraKey.cfrType.rawValue: ContextualHintViewType.toolbarLocation.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .contextualHint, value: .pressCFRActionButton, extras: extra)

        testEventMetricRecordingSuccess(metric: GleanMetrics.CfrAnalytics.pressCfrActionButton)
    }

    func test_contextualHintPressActionWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .contextualHint, value: .pressCFRActionButton)
        XCTAssertFalse(GleanMetrics.CfrAnalytics.pressCfrActionButton.testHasValue())
    }

    // MARK: - Tabs quantity

    func test_tabsNormalQuantity_GleanIsCalled() {
        let expectTabCount: Int64 = 80
        let extra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: expectTabCount]
        TelemetryWrapper.recordEvent(category: .information, method: .background, object: .tabNormalQuantity, value: nil, extras: extra)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity,
                                  expectedValue: expectTabCount,
                                  failureMessage: "Should have \(expectTabCount) tabs for normal tabs")
    }

    func test_tabsPrivateQuantity_GleanIsCalled() {
        let expectTabCount: Int64 = 60
        let extra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: expectTabCount]
        TelemetryWrapper.recordEvent(category: .information, method: .background, object: .tabPrivateQuantity, value: nil, extras: extra)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity,
                                  expectedValue: expectTabCount,
                                  failureMessage: "Should have \(expectTabCount) tabs for private tabs")
    }

    func test_tabsNormalQuantityWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .information, method: .background, object: .tabNormalQuantity, value: nil, extras: nil)
        XCTAssertFalse(GleanMetrics.Tabs.normalTabsQuantity.testHasValue())
    }

    func test_tabsPrivateQuantityWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(category: .information, method: .background, object: .tabPrivateQuantity, value: nil, extras: nil)
        XCTAssertFalse(GleanMetrics.Tabs.privateTabsQuantity.testHasValue())
    }

    // MARK: - Onboarding

    func test_onboardingCardViewWithExtras_GleanIsCalled() {
        let cardTypeKey = TelemetryWrapper.EventExtraKey.cardType.rawValue
        let extras = [cardTypeKey: "\(IntroViewModel.OnboardingCards.welcome.telemetryValue)"]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .onboardingCardView, value: nil, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func test_onboardingPrimaryButtonWithExtras_GleanIsCalled() {
        let cardTypeKey = TelemetryWrapper.EventExtraKey.cardType.rawValue
        let extras = [cardTypeKey: "\(IntroViewModel.OnboardingCards.welcome.telemetryValue)"]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .onboardingPrimaryButton, value: nil, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    func test_onboardingSecondaryButtonWithExtras_GleanIsCalled() {
        let cardTypeKey = TelemetryWrapper.EventExtraKey.cardType.rawValue
        let extras = [cardTypeKey: "\(IntroViewModel.OnboardingCards.welcome.telemetryValue)"]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .onboardingSecondaryButton, value: nil, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
    }

    func test_onboardingSelectWallpaperWithExtras_GleanIsCalled() {
        let wallpaperNameKey = TelemetryWrapper.EventExtraKey.wallpaperName.rawValue
        let wallpaperTypeKey = TelemetryWrapper.EventExtraKey.wallpaperType.rawValue
        let extras = [wallpaperNameKey: "defaultBackground",
                      wallpaperTypeKey: "default"]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .onboardingSelectWallpaper,
                                     value: .wallpaperSelected,
                                     extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.wallpaperSelected)
    }

    func test_onboardingCloseWithExtras_GleanIsCalled() {
        let cardTypeKey = TelemetryWrapper.EventExtraKey.cardType.rawValue
        let extras = [cardTypeKey: "\(IntroViewModel.OnboardingCards.welcome.telemetryValue)"]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .onboardingClose, value: nil, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.closeTap)
    }

    // MARK: - Migration

    func test_SDWebImageDiskCacheClear_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .information, method: .delete, object: .clearSDWebImageCache)
        testCounterMetricRecordingSuccess(metric: GleanMetrics.Migration.imageSdCacheCleanup)
    }
}

// MARK: - Helper functions to test telemetry
extension XCTestCase {

    func testEventMetricRecordingSuccess<Keys: ExtraKeys, Extras: EventExtras>(metric: EventMetricType<Keys, Extras>,
                                                                               file: StaticString = #file,
                                                                               line: UInt = #line) {
        XCTAssertTrue(metric.testHasValue())
        XCTAssertEqual(try! metric.testGetValue().count, 1)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }

    func testCounterMetricRecordingSuccess(metric: CounterMetricType,
                                           file: StaticString = #file,
                                           line: UInt = #line) {
        XCTAssertTrue(metric.testHasValue())
        XCTAssertEqual(try! metric.testGetValue(), 1)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }

    func testLabeledMetricSuccess(metric: LabeledMetricType<CounterMetricType>,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }

    func testQuantityMetricSuccess(metric: QuantityMetricType,
                                   expectedValue: Int64,
                                   failureMessage: String,
                                   file: StaticString = #file,
                                   line: UInt = #line) {
        XCTAssertTrue(metric.testHasValue(), "Should have value on quantity metric")
        XCTAssertEqual(try! metric.testGetValue(), expectedValue, failureMessage)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }

    func testStringMetricSuccess(metric: StringMetricType,
                                 expectedValue: String,
                                 failureMessage: String,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        XCTAssertTrue(metric.testHasValue(), "Should have value on string metric")
        XCTAssertEqual(try! metric.testGetValue(), expectedValue, failureMessage)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }

    func testUrlMetricSuccess(metric: UrlMetricType,
                              expectedValue: String,
                              failureMessage: String,
                              file: StaticString = #file,
                              line: UInt = #line) {
        XCTAssertTrue(metric.testHasValue(), "Should have value on url metric")
        XCTAssertEqual(try! metric.testGetValue(), expectedValue, failureMessage)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0)
    }

    func testUuidMetricSuccess(metric: UuidMetricType,
                               expectedValue: UUID,
                               failureMessage: String,
                               file: StaticString = #file,
                               line: UInt = #line) {

        guard let value = try? metric.testGetValue() else {
            XCTFail("Expected contextId to be configured")
            return
        }
        XCTAssertTrue(metric.testHasValue(), "Should have value on uuid metric")
        XCTAssertEqual(value, expectedValue, failureMessage)
    }
}
