// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class TelemetryWrapperTests: XCTestCase {
    typealias ExtraKey = TelemetryWrapper.EventExtraKey
    typealias ValueKey = TelemetryWrapper.EventValue

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        Experiments.events.clearEvents()
    }

    override func tearDown() {
        Experiments.events.clearEvents()
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // MARK: - Bookmarks

    func test_hasMobileBookmarks_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .doesHaveMobileBookmarks)

        testBoolMetricSuccess(metric: GleanMetrics.Bookmarks.hasMobileBookmarks,
                              expectedValue: true,
                              failureMessage: "Should have been set to true.")
    }

    func test_doesNotHaveMobileBookmarks_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .doesNotHaveMobileBookmarks)

        testBoolMetricSuccess(metric: GleanMetrics.Bookmarks.hasMobileBookmarks,
                              expectedValue: false,
                              failureMessage: "Should have been set to false.")
    }

    func test_mobileBookmarksQuantity_GleanIsCalled() {
        let quantityKey = TelemetryWrapper.EventExtraKey.mobileBookmarksQuantity.rawValue
        let expectedQuantity: Int64 = 13
        let extras = [quantityKey: expectedQuantity]

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .mobileBookmarksCount,
                                     extras: extras)

        testQuantityMetricSuccess(metric: GleanMetrics.Bookmarks.mobileBookmarksCount,
                                  expectedValue: 13,
                                  failureMessage: "Incorrect mobile bookmarks quantity returned.")
    }

    // MARK: - Top Site

    func test_topSiteTileWithExtras_GleanIsCalled() {
        let topSitePositionKey = TelemetryWrapper.EventExtraKey.topSitePosition.rawValue
        let topSiteTileTypeKey = TelemetryWrapper.EventExtraKey.topSiteTileType.rawValue
        let extras = [topSitePositionKey: "\(1)", topSiteTileTypeKey: "history-based"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .topSiteTile,
            value: nil,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.TopSites.tilePressed)
    }

    func test_topSiteTileWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .topSiteTile,
            value: nil
        )
        XCTAssertNil(GleanMetrics.TopSites.tilePressed.testGetValue())
    }

    func test_topSiteContextualMenu_GleanIsCalled() {
        let extras = [
            ExtraKey.contextualMenuType.rawValue: HomepageContextMenuHelper.ContextualActionType.settings.rawValue
        ]

        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .topSiteContextualMenu,
            value: nil,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.TopSites.contextualMenu)
    }

    func test_topSiteContextualMenuWithoutExtra_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .topSiteContextualMenu,
            value: nil,
            extras: nil
        )
        XCTAssertNil(GleanMetrics.TopSites.contextualMenu.testGetValue())
    }

    func test_sponsoredShortcuts_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .view,
            object: .sponsoredShortcuts,
            value: nil,
            extras: ["pref": true]
        )
        testBoolMetricSuccess(metric: GleanMetrics.TopSites.sponsoredShortcuts,
                              expectedValue: true,
                              failureMessage: "Sponsored shortcut value not tracked")
    }

    // MARK: - Preferences

    func test_preferencesWithExtras_GleanIsCalled() {
        let extras: [String: Any] = [
            ExtraKey.preference.rawValue: "ETP-strength",
            ExtraKey.preferenceChanged.rawValue: BlockingStrength.strict.rawValue
        ]

        TelemetryWrapper.recordEvent(
            category: .action,
            method: .change,
            object: .setting,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.Preferences.changed)
    }

    func test_preferencesWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .change,
            object: .setting
        )
        XCTAssertNil(GleanMetrics.Preferences.changed.testGetValue())
    }

    // MARK: - Firefox Home Page

    func test_recentlySavedBookmarkViewWithExtras_GleanIsCalled() {
        let extras: [String: Any] = [TelemetryWrapper.EventObject.bookmarkImpressions.rawValue: "\([String]().count)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .firefoxHomepage,
            value: .bookmarkItemView,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.FirefoxHomePage.recentlySavedBookmarkView)
    }

    func test_recentlySavedBookmarkViewWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .firefoxHomepage,
            value: .bookmarkItemView
        )
        XCTAssertNil(GleanMetrics.FirefoxHomePage.recentlySavedBookmarkView.testGetValue())
    }

    func test_firefoxHomePageAddView_GleanIsCalled() {
        let extras = [ExtraKey.fxHomepageOrigin.rawValue: ValueKey.fxHomepageOriginZeroSearch.rawValue]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .firefoxHomepage,
            value: .fxHomepageOrigin,
            extras: extras
        )

        testLabeledMetricSuccess(metric: GleanMetrics.FirefoxHomePage.firefoxHomepageOrigin)
    }

    // MARK: - CFR Analytics

    func test_contextualHintDismissButton_GleanIsCalled() {
        let extra = [TelemetryWrapper.EventExtraKey.cfrType.rawValue: ContextualHintType.toolbarLocation.rawValue]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .dismissCFRFromButton,
            extras: extra
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.CfrAnalytics.dismissCfrFromButton)
    }

    func test_contextualHintDismissButtonWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .dismissCFRFromButton
        )
        XCTAssertNil(GleanMetrics.CfrAnalytics.dismissCfrFromButton.testGetValue())
    }

    func test_contextualHintDismissOutsideTap_GleanIsCalled() {
        let extra = [TelemetryWrapper.EventExtraKey.cfrType.rawValue: ContextualHintType.toolbarLocation.rawValue]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .dismissCFRFromOutsideTap,
            extras: extra
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.CfrAnalytics.dismissCfrFromOutsideTap)
    }

    func test_contextualHintDismissOutsideTapWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .dismissCFRFromOutsideTap
        )
        XCTAssertNil(GleanMetrics.CfrAnalytics.dismissCfrFromOutsideTap.testGetValue())
    }

    func test_contextualHintPressAction_GleanIsCalled() {
        let extra = [TelemetryWrapper.EventExtraKey.cfrType.rawValue: ContextualHintType.toolbarLocation.rawValue]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .pressCFRActionButton,
            extras: extra
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.CfrAnalytics.pressCfrActionButton)
    }

    func test_contextualHintPressActionWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .pressCFRActionButton
        )
        XCTAssertNil(GleanMetrics.CfrAnalytics.pressCfrActionButton.testGetValue())
    }

    // MARK: - Tabs quantity

    func test_tabsNormalQuantity_GleanIsCalled() {
        let expectTabCount: Int64 = 80
        let extra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: expectTabCount]
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .background,
            object: .tabNormalQuantity,
            value: nil,
            extras: extra
        )

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity,
                                  expectedValue: expectTabCount,
                                  failureMessage: "Should have \(expectTabCount) tabs for normal tabs")
    }

    func test_tabsPrivateQuantity_GleanIsCalled() {
        let expectTabCount: Int64 = 60
        let extra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: expectTabCount]
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .background,
            object: .tabPrivateQuantity,
            value: nil,
            extras: extra
        )

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity,
                                  expectedValue: expectTabCount,
                                  failureMessage: "Should have \(expectTabCount) tabs for private tabs")
    }

    func test_tabsNormalQuantityWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .background,
            object: .tabNormalQuantity,
            value: nil,
            extras: nil
        )
        XCTAssertNil(GleanMetrics.Tabs.normalTabsQuantity.testGetValue())
    }

    func test_tabsPrivateQuantityWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .background,
            object: .tabPrivateQuantity,
            value: nil,
            extras: nil
        )
        XCTAssertNil(GleanMetrics.Tabs.privateTabsQuantity.testGetValue())
    }

    // MARK: - Shopping Experience (Fakespot)
    func test_shoppingAddressBarIconClicked_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.addressBarIconClicked)
    }

    func test_productPageVisits_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .view,
            object: .shoppingProductPageVisits
        )

        testCounterMetricRecordingSuccess(metric: GleanMetrics.Shopping.productPageVisits)
    }

    func test_shoppingAddressBarIconDisplayed_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.addressBarIconDisplayed)
    }

    func test_shoppingSurfaceClosedWithExtras_GleanIsCalledClickOutsideAction() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .shoppingBottomSheet,
            extras: [TelemetryWrapper.ExtraKey.action.rawValue:
                        TelemetryWrapper.EventExtraKey.Shopping.clickOutside.rawValue]
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceClosed)
    }

    func test_shoppingSurfaceClosedWithExtras_GleanIsCalledCloseButtonAction() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .shoppingBottomSheet,
            extras: [TelemetryWrapper.ExtraKey.action.rawValue:
                        TelemetryWrapper.EventExtraKey.Shopping.closeButton.rawValue]
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceClosed)
    }

    func test_shoppingSurfaceClosedWithExtras_GleanIsCalledInteractionWithALinkAction() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .shoppingBottomSheet,
            extras: [TelemetryWrapper.ExtraKey.action.rawValue:
                        TelemetryWrapper.EventExtraKey.Shopping.interactionWithALink.rawValue]
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceClosed)
    }

    func test_shoppingSurfaceClosedWithExtras_GleanIsCalledOptingOutOfTheFeatureAction() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .shoppingBottomSheet,
            extras: [TelemetryWrapper.ExtraKey.action.rawValue:
                        TelemetryWrapper.EventExtraKey.Shopping.optingOutOfTheFeature.rawValue]
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceClosed)
    }

    func test_shoppingSurfaceClosedWithExtras_GleanIsCalledSwipingTheSurfaceHandleAction() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .shoppingBottomSheet,
            extras: [TelemetryWrapper.ExtraKey.action.rawValue:
                        TelemetryWrapper.EventExtraKey.Shopping.swipingTheSurfaceHandle.rawValue]
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceClosed)
    }

    func test_shoppingSurfaceShowMoreRecentReviewsClicked_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingRecentReviews
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceShowMoreRecentReviewsClicked)
	}

    func test_shoppingSurfaceDisplayeddWithExtras_GleanIsCalledFullViewState() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            extras: [TelemetryWrapper.ExtraKey.size.rawValue:
                        TelemetryWrapper.EventExtraKey.Shopping.fullView.rawValue]
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceDisplayed)
    }

    func test_shoppingSurfaceDisplayeddWithExtras_GleanIsCalledHalfViewState() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            extras: [
                TelemetryWrapper.ExtraKey.size.rawValue: TelemetryWrapper.EventExtraKey.Shopping.halfView.rawValue
            ]
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceDisplayed)
    }

    func test_shoppingOnboardingDisplayed_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingOnboarding
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceOnboardingDisplayed)
    }

    func test_surfaceSettingsExpandClicked_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingSettingsChevronButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceSettingsExpandClicked)
    }

    func test_shoppingSurfaceOptIn_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingOptIn
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceOptInAccepted)
    }

    func test_shoppingSurfaceNotNow_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingNotNowButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceNotNowClicked)
    }

    func test_shoppingSurfaceOptInShowTerms_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingTermsOfUseButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceShowTermsClicked)
    }

    func test_shoppingSurfaceOptInShowPrivacyPolicy_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingPrivacyPolicyButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceShowPrivacyPolicyClicked)
    }

    func test_shoppingSurfaceOptInLearnMore_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingLearnMoreButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceLearnMoreClicked)
    }

    func test_shoppingSurfaceShowQualityExplainer_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingLearnMoreReviewQualityButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceShowQualityExplainerClicked)
    }

    func test_addressBarFeatureCalloutDisplayed_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .navigate,
            object: .shoppingButton,
            value: .shoppingCFRsDisplayed
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.addressBarFeatureCalloutDisplayed)
    }

    func test_surfacePoweredByFakespotLinkClicked_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingPoweredByFakespotLabel
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfacePoweredByFakespotLinkClicked)
    }

    func test_surfaceAnalyzeReviewsNoneAvailableClicked_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingNoAnalysisCardViewPrimaryButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceAnalyzeReviewsNoneAvailableClicked)
    }

    func test_surfaceReanalyzeClicked_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingNeedsAnalysisCardViewPrimaryButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceReanalyzeClicked)
    }

    func test_surfaceReactivatedButtonClicked_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingProductBackInStockButton
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceReactivatedButtonClicked)
    }

    func test_surfaceNoReviewReliabilityAvailable_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .navigate,
            object: .shoppingBottomSheet
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceNoReviewReliabilityAvailable)
    }

    func test_shoppingShoppingSurfaceStaleAnalysisShown_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingSurfaceStaleAnalysisShown
        )
        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceStaleAnalysisShown)
    }

    func test_shoppingAdsSettingToggle_GleanIsCalled() {
        let isEnabled = TelemetryWrapper.EventExtraKey.Shopping.adsSettingToggle.rawValue
        let extras = [isEnabled: true]
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .shoppingAdsSettingToggle, extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Shopping.surfaceAdsSettingToggled)
    }

    func test_shoppingNimbusDisabled_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .settings,
            object: .shoppingNimbusDisabled,
            extras: [
                TelemetryWrapper.ExtraKey.Shopping.isNimbusDisabled.rawValue: true
            ])
        testBoolMetricSuccess(metric: GleanMetrics.ShoppingSettings.nimbusDisabledShopping,
                              expectedValue: true,
                              failureMessage: "Should be true")
    }

    func test_shoppingComponentOptedOut_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .settings,
            object: .shoppingComponentOptedOut,
            extras: [
                TelemetryWrapper.ExtraKey.Shopping.isComponentOptedOut.rawValue: true
            ])
        testBoolMetricSuccess(metric: GleanMetrics.ShoppingSettings.componentOptedOut,
                              expectedValue: true,
                              failureMessage: "Should be true")
    }

    func test_shoppingUserHasOnboarded_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .settings,
            object: .shoppingUserHasOnboarded,
            extras: [
                TelemetryWrapper.ExtraKey.Shopping.isUserOnboarded.rawValue: true
            ])
        testBoolMetricSuccess(metric: GleanMetrics.ShoppingSettings.userHasOnboarded,
                              expectedValue: true,
                              failureMessage: "Should be true")
    }

    func test_shoppingAdsDisabledStatus_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .settings,
            object: .shoppingAdsOptedOut,
            extras: [
                TelemetryWrapper.ExtraKey.Shopping.areAdsDisabled.rawValue: true
            ])
        testBoolMetricSuccess(metric: GleanMetrics.ShoppingSettings.disabledAds,
                              expectedValue: true,
                              failureMessage: "Should be true")
    }

    func test_shoppingAdsExposure_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            value: .shoppingAdsExposure
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Shopping.adsExposure
        )
    }

    func test_shoppingNoAdsAvailable_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            value: .shoppingNoAdsAvailable
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Shopping.surfaceNoAdsAvailable
        )
    }

    func test_surfaceAdsImpression_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            value: .shoppingAdsImpression
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Shopping.surfaceAdsImpression
        )
    }

    func test_surfaceAdsClicked_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            value: .surfaceAdsClicked
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Shopping.surfaceAdsClicked
        )
    }

    // MARK: - Onboarding
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

    func test_onboardingNotificationPermission_GleanIsCalled() {
        let isGrantedKey = TelemetryWrapper.EventExtraKey.notificationPermissionIsGranted.rawValue
        let extras = [isGrantedKey: true]
        TelemetryWrapper.recordEvent(category: .prompt,
                                     method: .tap,
                                     object: .notificationPermission,
                                     extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.notificationPermissionPrompt)
    }

    func test_onboardingEngagementNotificationTapped_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .engagementNotification)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.engagementNotificationTapped)
    }

    func test_onboardingEngagementNotificationCancel_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .cancel,
                                     object: .engagementNotification)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.engagementNotificationCancel)
    }

    // MARK: Wallpapers

    func test_backgroundWallpaperMetric_defaultBackgroundIsNotSent() {
        let profile = MockProfile()
        TelemetryWrapper.shared.setup(profile: profile)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)

        let defaultWallpaper = Wallpaper(id: "fxDefault",
                                         textColor: nil,
                                         cardColor: nil,
                                         logoTextColor: nil)

        WallpaperManager().setCurrentWallpaper(to: defaultWallpaper) { _ in }
        XCTAssertEqual(WallpaperManager().currentWallpaper.type, .none)

        let fakeNotif = NSNotification(name: UIApplication.didEnterBackgroundNotification, object: nil)
        TelemetryWrapper.shared.recordEnteredBackgroundPreferenceMetrics(notification: fakeNotif)

        testLabeledMetricSuccess(metric: GleanMetrics.WallpaperAnalytics.themedWallpaper)
        let wallpaperName = WallpaperManager().currentWallpaper.id.lowercased()
        XCTAssertNil(GleanMetrics.WallpaperAnalytics.themedWallpaper[wallpaperName].testGetValue())
    }

    func test_backgroundWallpaperMetric_themedWallpaperIsSent() {
        let profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        TelemetryWrapper.shared.setup(profile: profile)

        let themedWallpaper = Wallpaper(id: "amethyst",
                                        textColor: nil,
                                        cardColor: nil,
                                        logoTextColor: nil)

        WallpaperManager().setCurrentWallpaper(to: themedWallpaper) { _ in }
        XCTAssertEqual(WallpaperManager().currentWallpaper.type, .other)

        let fakeNotif = NSNotification(name: UIApplication.didEnterBackgroundNotification, object: nil)
        TelemetryWrapper.shared.recordEnteredBackgroundPreferenceMetrics(notification: fakeNotif)

        testLabeledMetricSuccess(metric: GleanMetrics.WallpaperAnalytics.themedWallpaper)
        let wallpaperName = WallpaperManager().currentWallpaper.id.lowercased()
        XCTAssertEqual(GleanMetrics.WallpaperAnalytics.themedWallpaper[wallpaperName].testGetValue(), 1)
    }

    // MARK: - Awesomebar result tap
    func test_AwesomebarImpressions_GleanIsCalled() {
        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = SearchTelemetryValues.Groups.adaptiveHistory.rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = SearchTelemetryValues.Interaction.persistedSearchTerms.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars: Int32 = 5

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults: Int32 = 12

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords: Int32 = 1

        let reasonKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.reason.rawValue
        let reason = SearchTelemetryValues.Reason.pause.rawValue

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = SearchTelemetryValues.Results.searchEngine.rawValue + ","
                      + SearchTelemetryValues.Results.tabToSearch.rawValue

        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = SearchTelemetryValues.Sap.urlbar.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.bookmarks.rawValue

        let extraDetails = [
            groupsKey: groups,
            interactionKey: interaction,
            nCharsKey: nChars,
            nResultsKey: nResults,
            nWordsKey: nWords,
            reasonKey: reason,
            resultsKey: results,
            sapKey: sap,
            searchModeKey: searchMode
        ] as [String: Any]

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .urlbarImpression,
                                     extras: extraDetails)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Urlbar.impression)
    }

    func test_AwesomebarEngagement_GleanIsCalled() {
        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = SearchTelemetryValues.Sap.urlbar.rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = SearchTelemetryValues.Interaction.persistedSearchTerms.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.tabs.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars: Int32 = 5

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults: Int32 = 12

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords: Int32 = 1

        let selectedResultKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.selectedResult.rawValue
        let selectedResult = SearchTelemetryValues.SelectedResult.topSite.rawValue

        let selectedResultSubtypeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.selectedResultSubtype.rawValue
        let selectedResultSubtype = "unknown"

        let providerKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.provider.rawValue
        let provider = SearchEngine.none.rawValue

        let engagementTypeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.engagementType.rawValue
        let engagementType = SearchTelemetryValues.EngagementType.help.rawValue

        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = SearchTelemetryValues.Groups.adaptiveHistory.rawValue

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = SearchTelemetryValues.Results.searchEngine.rawValue + ","
        + SearchTelemetryValues.Results.tabToSearch.rawValue

        let extraDetails = [
            sapKey: sap,
            interactionKey: interaction,
            searchModeKey: searchMode,
            nCharsKey: nChars,
            nWordsKey: nWords,
            nResultsKey: nResults,
            selectedResultKey: selectedResult,
            selectedResultSubtypeKey: selectedResultSubtype,
            providerKey: provider,
            engagementTypeKey: engagementType,
            groupsKey: groups,
            resultsKey: results]
        as [String: Any]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .urlbarEngagement,
                                     extras: extraDetails)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Urlbar.engagement)
    }

  func test_AwesomebarAbandonment_GleanIsCalled() {
        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = SearchTelemetryValues.Groups.adaptiveHistory.rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = SearchTelemetryValues.Interaction.persistedSearchTerms.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars: Int32 = 5

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults: Int32 = 12

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords: Int32 = 1

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = SearchTelemetryValues.Results.searchEngine.rawValue + ","
        + SearchTelemetryValues.Results.tabToSearch.rawValue

        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = SearchTelemetryValues.Sap.urlbar.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.bookmarks.rawValue

        let extraDetails = [
            groupsKey: groups,
            interactionKey: interaction,
            nCharsKey: nChars,
            nResultsKey: nResults,
            nWordsKey: nWords,
            resultsKey: results,
            sapKey: sap,
            searchModeKey: searchMode
        ] as [String: Any]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .urlbarAbandonment,
                                     extras: extraDetails)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Urlbar.abandonment)
    }

    // MARK: - Page Action Menu

    func test_createNewTab_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .createNewTab
        )

        testCounterMetricRecordingSuccess(metric: GleanMetrics.PageActionMenu.createNewTab)
    }

    // MARK: - History

    func test_HistoryPanelOpened_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .historyPanelOpened)

        testEventMetricRecordingSuccess(metric: GleanMetrics.History.opened)
    }

    func test_openedHistoryItem_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .openedHistoryItem)

        testEventMetricRecordingSuccess(metric: GleanMetrics.History.openedItem)
    }

    func test_singleHistoryItemRemoved_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .swipe,
                                     object: .historySingleItemRemoved)

        testEventMetricRecordingSuccess(metric: GleanMetrics.History.removed)
    }

    func test_viewHistoryPanel_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .viewHistoryPanel
        )

        testCounterMetricRecordingSuccess(metric: GleanMetrics.PageActionMenu.viewHistoryPanel)
    }

    func test_viewDownloadsPanel_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .viewDownloadsPanel
        )

        testCounterMetricRecordingSuccess(metric: GleanMetrics.PageActionMenu.viewDownloadsPanel)
    }

    // Accessibility

    func test_accessibilityVoiceOver_GleanIsCalled() {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isVoiceOverRunning.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .voiceOver,
            object: .app,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.voiceOver)
    }

    func test_accessibilitySwitchControl_GleanIsCalled() {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isSwitchControlRunning.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .switchControl,
            object: .app,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.switchControl)
    }

    func test_accessibilityReduceTransparency_GleanIsCalled() {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isReduceTransparencyEnabled.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .reduceTransparency,
            object: .app,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.reduceTransparency)
    }

    func test_accessibilityReduceMotionEnabled_GleanIsCalled() {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isReduceMotionEnabled.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .reduceMotion,
            object: .app,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.reduceMotion)
    }

    func test_accessibilityInvertColorsEnabled_GleanIsCalled() {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isInvertColorsEnabled.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .invertColors,
            object: .app,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.invertColors)
    }

    func test_accessibilityDynamicText_GleanIsCalled() {
        let isAccessibilitySizeEnabledKey = TelemetryWrapper.EventExtraKey.isAccessibilitySizeEnabled.rawValue
        let preferredContentSizeCategoryKey = TelemetryWrapper.EventExtraKey.preferredContentSizeCategory.rawValue
        let extras = [isAccessibilitySizeEnabledKey: "\(1)",
                    preferredContentSizeCategoryKey: "UICTContentSizeCategoryAccessibilityL"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .dynamicTextSize,
            object: .app,
            extras: extras
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.dynamicText)
    }

    // MARK: - App Settings Menu

    func test_showTour_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .settingsMenuShowTour
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.SettingsMenu.showTourPressed)
    }

    func test_signIntoSync_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .signIntoSync)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.AppMenu.signIntoSync)
    }

    func test_settingsMenuSync_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .settingsMenuPasswords)
        testEventMetricRecordingSuccess(metric: GleanMetrics.SettingsMenu.passwords)
    }

    func test_appMenuLoginsAndPasswordsTapped_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .logins)
        testEventMetricRecordingSuccess(metric: GleanMetrics.AppMenu.passwords)
    }

    // MARK: Logins and Passwords
    func test_loginsAutofilled_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .loginsAutofilled)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.autofilled)
    }

    func test_loginsAutofillFailed_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .loginsAutofillFailed)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.autofillFailed)
    }

    func test_loginsManagementAddTapped_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .loginsManagementAddTapped)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.managementAddTapped)
    }

    func test_loginsManagementLoginsTapped_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .loginsManagementLoginsTapped)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.managementLoginsTapped)
    }

    func test_loginsModified_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .change,
                                     object: .loginsModified)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.modified)
    }

    func test_loginsDeleted_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .delete,
                                     object: .loginsDeleted)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.deleted)
    }

    func test_loginsSaved_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .loginsSaved)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.saved)
    }

    func test_loginsSyncEnabled_GleanIsCalled() {
        let isEnabledKey = TelemetryWrapper.EventExtraKey.isLoginSyncEnabled.rawValue
        let extras = [isEnabledKey: true]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsSyncEnabled,
                                     extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.syncEnabled)
    }

    func test_loginsSavedAll_GleanIsCalled() {
        let expectedLoginsCount: Int64 = 5
        let extra = [TelemetryWrapper.EventExtraKey.loginsQuantity.rawValue: expectedLoginsCount]
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .foreground,
            object: .loginsSavedAll,
            value: nil,
            extras: extra
        )

        testQuantityMetricSuccess(
            metric: GleanMetrics.Logins.savedAll,
            expectedValue: expectedLoginsCount,
            failureMessage: "Should have \(expectedLoginsCount) logins"
        )
    }
    // MARK: - Sync

    func test_userLoggedOut_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncUserLoggedOut)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Sync.disconnect)
    }

    func test_loginWithQRCode_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncSignInScanQRCode)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Sync.paired)
    }

    func test_loginWithEmail_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncSignInUseEmail)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Sync.useEmail)
    }

    // MARK: - Address autofill

    func test_addressSavedAll_GleanIsCalledWithQuantity() {
        let expectedAddressesCount: Int64 = 5
        let extras: [String: Any] = [TelemetryWrapper.EventExtraKey.AddressTelemetry.count.rawValue: Int64(5)]
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .foreground,
            object: .addressAutofillSettings,
            value: nil,
            extras: extras
        )

        testQuantityMetricSuccess(metric: GleanMetrics.Addresses.savedAll,
                                  expectedValue: expectedAddressesCount,
                                  failureMessage: "Should have \(expectedAddressesCount) addresses")
    }

    func test_addressSettingsAutofill_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .addressAutofillSettings
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.settingsAutofill
        )
    }

    func test_addressAutofillPromptShown_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .addressAutofillPromptShown
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.autofillPromptShown
        )
    }

    func test_addressAutofillPromptExpanded_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .addressAutofillPromptExpanded
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.autofillPromptExpanded
        )
    }

    func test_addressAutofillPromptDismissed_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .addressAutofillPromptDismissed
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.autofillPromptDismissed
        )
    }

    func test_addressFormFilledModified_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .change,
            object: .addressFormFilledModified
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.modified
        )
    }

    func test_addressFormAutofilled_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .detect,
            object: .addressFormFilled
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.autofilled
        )
    }

    func test_addressFormDetected_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .detect,
            object: .addressForm
        )
        testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.formDetected
        )
    }

    // MARK: - Credit card autofill

    func test_autofill_credit_card_settings_tapped_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .creditCardAutofillSettings
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.autofillSettingsTapped)
    }

    func test_creditCardAutofillPromptShown_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .creditCardAutofillPromptShown)
        testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.autofillPromptShown)
    }

    func test_creditCardAutofillPromptExpanded_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardAutofillPromptExpanded)
        testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.autofillPromptExpanded)
    }

    func test_creditCardAutofillPromptDismissed_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .creditCardAutofillPromptDismissed)
        testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.autofillPromptDismissed)
    }

    func test_creditCardSavePromptShown_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .creditCardSavePromptShown)
        testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.savePromptShown)
    }

    func test_creditCardSavePromptUpdate_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardSavePromptUpdate)
        testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.savePromptUpdate)
    }

    func test_creditCardManagementAddTapped_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardManagementAddTapped)
        testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.managementAddTapped)
    }

    func test_creditCardManagementCardTapped_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardManagementCardTapped)
        testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.managementCardTapped)
    }

    func test_creditCardModified_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .change,
                                     object: .creditCardModified)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.CreditCard.modified)
    }

    func test_creditCardDeleted_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .delete,
                                     object: .creditCardDeleted)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.CreditCard.deleted)
    }

    func test_creditCardSaved_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .creditCardSaved)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.CreditCard.saved)
    }

    func test_creditCardSavedAll_GleanIsCalled() {
        let expectedCreditCardsCount: Int64 = 5
        let extra = [TelemetryWrapper.EventExtraKey.creditCardsQuantity.rawValue: expectedCreditCardsCount]
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .foreground,
            object: .creditCardSavedAll,
            value: nil,
            extras: extra
        )

        testQuantityMetricSuccess(metric: GleanMetrics.CreditCard.savedAll,
                                  expectedValue: expectedCreditCardsCount,
                                  failureMessage: "Should have \(expectedCreditCardsCount) credit cards")
    }
    // MARK: - App

    func test_appNotificationPermission_GleanIsCalled() {
        let statusKey = TelemetryWrapper.EventExtraKey.notificationPermissionStatus.rawValue
        let alertSettingKey = TelemetryWrapper.EventExtraKey.notificationPermissionAlertSetting.rawValue
        let extras = [statusKey: "authorized", alertSettingKey: "enabled"]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .notificationPermission,
                                     extras: extras)

        testEventMetricRecordingSuccess(metric: GleanMetrics.App.notificationPermission)
    }

    // MARK: - Nimbus Calls

    func test_appForeground_NimbusIsCalled() throws {
        XCTAssertFalse(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'app_cycle.foreground'|eventSum('Days', 1, 0) > 0"
            )
        )
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .foreground,
            object: .app,
            value: nil
        )
        Experiments.shared.waitForDbQueue()
        XCTAssertTrue(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'app_cycle.foreground'|eventSum('Days', 1, 0) > 0"
            )
        )
    }

    func test_syncLogin_NimbusIsCalled() {
        XCTAssertFalse(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'sync.login_completed_view'|eventSum('Days', 1, 0) > 0"
            )
        )
        TelemetryWrapper.recordEvent(
            category: .firefoxAccount,
            method: .view,
            object: .fxaLoginCompleteWebpage,
            value: nil
        )
        Experiments.shared.waitForDbQueue()
        XCTAssertTrue(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'sync.login_completed_view'|eventSum('Days', 1, 0) > 0"
            )
        )
    }

    // MARK: - App Errors

    func test_error_largeFileWriteIsCalled() {
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: Int32(1000)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .largeFileWrite,
                                     extras: eventExtra)

        testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.largeFileWrite)
    }

    func test_error_crashedLastLaunchIsCalled() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .crashedLastLaunch)

        testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.crashedLastLaunch)
    }

    func test_error_cpuExceptionIsCalled() {
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: Int32(1000)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .cpuException,
                                     extras: eventExtra)

        testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.cpuException)
    }

    func test_error_hangExceptionIsCalled() {
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: Int32(1000)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .hangException,
                                     extras: eventExtra)

        testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.hangException)
    }

    func test_error_tabLossDetectedIsCalled() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .tabLossDetected)

        testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.tabLossDetected)
    }

    // MARK: - RecordSearch
    func test_RecordSearch_GleanIsCalledSearchSuggestion() {
        let extras = [TelemetryWrapper.EventExtraKey.recordSearchLocation.rawValue: "suggestion",
                      TelemetryWrapper.EventExtraKey.recordSearchEngineID.rawValue: "default"] as [String: Any]
        TelemetryWrapper.gleanRecordEvent(category: .action,
                                          method: .tap,
                                          object: .recordSearch,
                                          extras: extras)
    }

    func test_RecordSearch_GleanIsCalledSearchQuickSearch() {
        let extras = [TelemetryWrapper.EventExtraKey.recordSearchLocation.rawValue: "quickSearch",
                      TelemetryWrapper.EventExtraKey.recordSearchEngineID.rawValue: "default"] as [String: Any]
        TelemetryWrapper.gleanRecordEvent(category: .action,
                                          method: .tap,
                                          object: .recordSearch,
                                          extras: extras)
    }

    // MARK: - Webview

    func testRecordWebviewWhenDidFailThenGleanIsCalled() {
        TelemetryWrapper.gleanRecordEvent(category: .information,
                                          method: .error,
                                          object: .webview,
                                          value: .webviewFail)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Webview.didFail)
    }

    func testRecordWebviewWhenDidFailProvisionalThenGleanIsCalled() {
        TelemetryWrapper.gleanRecordEvent(category: .information,
                                          method: .error,
                                          object: .webview,
                                          value: .webviewFailProvisional)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Webview.didFailProvisional)
    }

    func testRecordWebviewWhenDidShowErrorThenGleanIsCalled() {
        let extra = [TelemetryWrapper.EventExtraKey.errorCode.rawValue: "403"]
        TelemetryWrapper.gleanRecordEvent(category: .information,
                                          method: .error,
                                          object: .webview,
                                          value: .webviewShowErrorPage,
                                          extras: extra)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Webview.showErrorPage)
    }

    func testRecordIfUserDefault() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .open,
                                     object: .defaultBrowser,
                                     extras: [TelemetryWrapper.EventExtraKey.isDefaultBrowser.rawValue: true])
        testBoolMetricSuccess(metric: GleanMetrics.App.defaultBrowser,
                              expectedValue: true,
                              failureMessage: "Failed to record is default browser")
    }

    func testRecordChoiceScreenAcquisition() {
        let key = TelemetryWrapper.EventExtraKey.didComeFromBrowserChoiceScreen.rawValue
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .open,
                                     object: .choiceScreenAcquisition,
                                     extras: [key: true])
        testBoolMetricSuccess(metric: GleanMetrics.App.choiceScreenAcquisition,
                              expectedValue: true,
                              failureMessage: "Failed to record choice screen acquisition")
    }
}

// MARK: - Helper functions to test telemetry
extension XCTestCase {
    func testEventMetricRecordingSuccess<ExtraObject>(
        metric: EventMetricType<ExtraObject>,
        expectedCount: Int = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) where ExtraObject: EventExtras {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on event metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue()!.count, expectedCount, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testCounterMetricRecordingSuccess(metric: CounterMetricType,
                                           value: Int32 = 1,
                                           file: StaticString = #file,
                                           line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on counter metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), value, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testLabeledMetricSuccess(metric: LabeledMetricType<CounterMetricType>,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testQuantityMetricSuccess(metric: QuantityMetricType,
                                   expectedValue: Int64,
                                   failureMessage: String,
                                   file: StaticString = #file,
                                   line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on quantity metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testStringMetricSuccess(metric: StringMetricType,
                                 expectedValue: String,
                                 failureMessage: String,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on string metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testUrlMetricSuccess(metric: UrlMetricType,
                              expectedValue: String,
                              failureMessage: String,
                              file: StaticString = #file,
                              line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on url metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testUuidMetricSuccess(metric: UuidMetricType,
                               expectedValue: UUID,
                               failureMessage: String,
                               file: StaticString = #file,
                               line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on uuid metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)
    }

    func testBoolMetricSuccess(metric: BooleanMetricType,
                               expectedValue: Bool,
                               failureMessage: String,
                               file: StaticString = #file,
                               line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on bool metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)
    }
}
