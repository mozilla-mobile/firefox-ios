// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class SummarizerNimbusUtilsTests: XCTestCase {
    private var profile: MockProfile!
    private let testLocale = Locale(identifier: "it")
    private let userDefaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        // Set features to default values
        setHostedSummarizerFeature()
        setIsAppleIntelligenceAvailable()
        setLanguageExpansionFeature()
    }

    override func tearDown() {
        profile = nil
        super.tearDown()
    }

    // MARK: - isSummarizeFeatureToggledOn Tests

    func test_isSummarizeFeatureToggledOn_whenFeatureEnabledAndUserEnabled() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)

        XCTAssertTrue(subject.isSummarizeFeatureToggledOn)
    }

    func test_isSummarizeFeatureToggledOn_whenFeatureEnabledButUserDisabled() {
        let subject = createSubject()
        profile.prefs.setBool(false, forKey: PrefsKeys.Summarizer.summarizeContentFeature)

        XCTAssertFalse(subject.isSummarizeFeatureToggledOn)
    }

    func test_isSummarizeFeatureToggledOn_whenFeatureDisabledButUserEnabled() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        setIsAppleIntelligenceAvailable(isEnabled: false)
        setHostedSummarizerFeature(isEnabled: false)

        XCTAssertFalse(subject.isSummarizeFeatureToggledOn)
    }

    func test_isSummarizeFeatureToggledOn_whenBothDisabled() {
        let subject = createSubject()
        profile.prefs.setBool(false, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        setIsAppleIntelligenceAvailable(isEnabled: false)
        setHostedSummarizerFeature(isEnabled: false)

        XCTAssertFalse(subject.isSummarizeFeatureToggledOn)
    }

    // MARK: - isSummarizeFeatureEnabled Tests

    func test_isSummarizeFeatureEnabled_whenAppleSummarizerEnabled() {
        let subject = createSubject()
        // disable the hosted to make sure it returns true for the apple summarizer that is enabled by default
        setHostedSummarizerFeature(isEnabled: false)

        XCTAssertTrue(subject.isSummarizeFeatureEnabled)
    }

    func test_isSummarizeFeatureEnabled_whenHostedSummarizerEnabled() {
        let subject = createSubject()
        // disable the apple summarizer to make sure it returns true for the hosted summarizer that is enabled by default
        setIsAppleIntelligenceAvailable(isEnabled: false)

        XCTAssertTrue(subject.isSummarizeFeatureEnabled)
    }

    func test_isSummarizeFeatureEnabled_whenBothDisabled() {
        let subject = createSubject()
        setIsAppleIntelligenceAvailable(isEnabled: false)
        setHostedSummarizerFeature(isEnabled: false)

        XCTAssertFalse(subject.isSummarizeFeatureEnabled)
    }

    // MARK: - isToolbarButtonEnabled Tests

    func test_isToolbarButtonEnabled_whenFeatureOnAndToolbarEndpointEnabled() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)

        XCTAssertTrue(subject.isToolbarButtonEnabled)
    }

    func test_isToolbarButtonEnabled_whenFeatureOff() {
        let subject = createSubject()
        profile.prefs.setBool(false, forKey: PrefsKeys.Summarizer.summarizeContentFeature)

        XCTAssertFalse(subject.isToolbarButtonEnabled)
    }

    func test_isToolbarButtonEnabled_whenToolbarEndpointDisabled() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        setHostedSummarizerFeature(toolbarEntrypoint: false)

        XCTAssertFalse(subject.isToolbarButtonEnabled)
    }

    // MARK: - isShakeGestureEnabled Tests

    func test_isShakeGestureEnabled_whenAllConditionsMet() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.shakeGestureEnabled)

        XCTAssertTrue(subject.isShakeGestureEnabled)
    }

    func test_isShakeGestureEnabled_whenFeatureOff() {
        let subject = createSubject()
        profile.prefs.setBool(false, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.shakeGestureEnabled)

        XCTAssertFalse(subject.isShakeGestureEnabled)
    }

    func test_isShakeGestureEnabled_whenFlagDisabled() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.shakeGestureEnabled)
        setHostedSummarizerFeature(shakeGesture: false)

        XCTAssertFalse(subject.isShakeGestureEnabled)
    }

    func test_isShakeGestureEnabled_whenUserSettingDisabled() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        profile.prefs.setBool(false, forKey: PrefsKeys.Summarizer.shakeGestureEnabled)

        XCTAssertFalse(subject.isShakeGestureEnabled)
    }

    // MARK: - isAppleSummarizerEnabled
    func test_isAppleSummarizerEnabled_whenLangExpansionDisabled() {
        let subject = createSubject()
        setLanguageExpansionFeature(isEnabled: false)
        
        XCTAssertTrue(subject.isAppleSummarizerEnabled())
    }
    
    func test_isAppleSummarizerEnabled_whenLangExpansionDisabledAndNonEnLocale() {
        let subject = createSubject(locale: testLocale)
        setLanguageExpansionFeature(isEnabled: false)
        
        XCTAssertFalse(subject.isAppleSummarizerEnabled())
    }
    
    func test_isAppleSummarizerEnabled_whenLangExpansionDisabledAndAppleIntelligenceDisabled() {
        let subject = createSubject(locale: testLocale)
        setLanguageExpansionFeature(isEnabled: false)
        setIsAppleIntelligenceAvailable(isEnabled: false)
        
        XCTAssertFalse(subject.isAppleSummarizerEnabled())
    }
    
    func test_isAppleSummarizerEnabled_whenLangExpansionEnabled() {
        let subject = createSubject()
        
        XCTAssertTrue(subject.isAppleSummarizerEnabled())
    }

    // MARK: - isHostedSummarizerEnabled Tests

    func test_isHostedSummarizerEnabled_whenFeatureFlagEnabled() {
        let subject = createSubject()
        setHostedSummarizerFeature(isEnabled: true)

        XCTAssertTrue(subject.isHostedSummarizerEnabled())
    }

    func test_isHostedSummarizerEnabled_whenFeatureFlagDisabled() {
        let subject = createSubject()
        setHostedSummarizerFeature(isEnabled: false)

        XCTAssertFalse(subject.isHostedSummarizerEnabled())
    }

    // MARK: - isShakeGestureFeatureFlagEnabled Tests

    func test_isShakeGestureFeatureFlagEnabled_whenAppleShakeEnabled() {
        let subject = createSubject()
        setHostedSummarizerFeature(shakeGesture: false)

        XCTAssertTrue(subject.isShakeGestureFeatureFlagEnabled())
    }

    func test_isShakeGestureFeatureFlagEnabled_whenHostedShakeEnabled() {
        let subject = createSubject()
        setHostedSummarizerFeature(shakeGesture: true)

        XCTAssertTrue(subject.isShakeGestureFeatureFlagEnabled())
    }

    // MARK: - languageExpansionConfiguration
    func test_languageExpansionConfiguration() {
        let subject = createSubject()
        let testLocales = [
            NimbusLocale(countryCode: "US", languageCode: "en"),
            NimbusLocale(countryCode: nil, languageCode: "es")
        ]
        setLanguageExpansionFeature(
            isEnabled: false,
            supportWebsiteLanguage: false,
            supportDeviceLanguage: false,
            supportedLocales: testLocales
        )

        let config = subject.languageExpansionConfiguration()

        XCTAssertFalse(config.isFeatureEnabled)
        XCTAssertFalse(config.isDeviceLanguageSupported)
        XCTAssertFalse(config.isWebsiteDeviceLanguageSupported)
        XCTAssertEqual(config.supportedLocales.count, testLocales.count)
        XCTAssertEqual(config.supportedLocales[0].identifier, "en-US")
        XCTAssertEqual(config.supportedLocales[1].identifier, "es")
    }

    // MARK: - Helper
    private func createSubject(
        locale: Locale = Locale(identifier: "en")
    ) -> DefaultSummarizerNimbusUtils {
        return DefaultSummarizerNimbusUtils(
            profile: profile,
            deviceLocale: locale,
            appleIntelligenceUtil: AppleIntelligenceUtil(
                userDefaults: userDefaults
            )
        )
    }

    private func setHostedSummarizerFeature(
        isEnabled: Bool = true,
        shakeGesture: Bool = true,
        toolbarEntrypoint: Bool = true
    ) {
        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(
                enabled: isEnabled,
                shakeGesture: shakeGesture,
                toolbarEntrypoint: toolbarEntrypoint
            )
        }
    }
    
    private func setIsAppleIntelligenceAvailable(isEnabled: Bool = true) {
        userDefaults.set(
            isEnabled,
            forKey: PrefsKeys.appleIntelligenceAvailable
        )
    }

    private func setLanguageExpansionFeature(
        isEnabled: Bool = true,
        supportWebsiteLanguage: Bool = true,
        supportDeviceLanguage: Bool = true,
        supportedLocales: [NimbusLocale] = []
    ) {
        FxNimbus.shared.features.summarizerLanguageExpansionFeature.with { _, _ in
            return SummarizerLanguageExpansionFeature(
                enabled: isEnabled,
                supportDeviceLanguage: supportDeviceLanguage,
                supportWebsiteLanguage: supportWebsiteLanguage,
                supportedLocales: supportedLocales
            )
        }
    }
}
