// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class SummarizerNimbusUtilsTests: XCTestCase {
    private var profile: MockProfile!
    private let itTestLocale = Locale(identifier: "it")
    private let userDefaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        // Set features to default values
        setHostedSummarizerFeature()
        setIsAppleIntelligenceAvailable()
        setLanguageExpansionFeature()
        setIsAppAttestAuthEnabled()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        profile = nil
        super.tearDown()
    }

    // MARK: - isSummarizeFeatureToggledOn
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

    // MARK: - isSummarizeFeatureEnabled
    func test_isSummarizeFeatureEnabled_whenHostedSummarizerDisabled() {
        let subject = createSubject()
        setHostedSummarizerFeature(isEnabled: false)

        XCTAssertTrue(subject.isSummarizeFeatureEnabled)
    }

    func test_isSummarizeFeatureEnabled_whenAppleSummarizerDisabled() {
        let subject = createSubject()
        setIsAppleIntelligenceAvailable(isEnabled: false)

        XCTAssertTrue(subject.isSummarizeFeatureEnabled)
    }

    func test_isSummarizeFeatureEnabled_whenBothExperimentsDisabled() {
        let subject = createSubject()
        setIsAppleIntelligenceAvailable(isEnabled: false)
        setHostedSummarizerFeature(isEnabled: false)

        XCTAssertFalse(subject.isSummarizeFeatureEnabled)
    }

    // MARK: - isToolbarButtonEnabled
    func test_isToolbarButtonEnabled() {
        let subject = createSubject()

        XCTAssertTrue(subject.isToolbarButtonEnabled)
    }

    func test_isToolbarButtonEnabled_whenFeatureFlagOff() {
        let subject = createSubject()
        setHostedSummarizerFeature(toolbarEntrypoint: false)
        setIsAppleIntelligenceAvailable(isEnabled: false)

        XCTAssertFalse(subject.isToolbarButtonEnabled)
    }

    // MARK: - isLanguageExpansionEnabled
    func test_isLanguageExpansionEnabled() {
        let subject = createSubject()

        XCTAssertTrue(subject.isLanguageExpansionEnabled)
    }

    func test_isLanguageExpansionEnabled_whenFeatureFlagOff() {
        let subject = createSubject()
        setLanguageExpansionFeature(isEnabled: false)

        XCTAssertFalse(subject.isLanguageExpansionEnabled)
    }

    // MARK: - isShakeGestureEnabled
    func test_isShakeGestureEnabled_whenAllConditionsMet() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.shakeGestureEnabled)

        XCTAssertTrue(subject.isShakeGestureEnabled)
    }

    func test_isShakeGestureEnabled_whenFeatureToggledOff() {
        let subject = createSubject()
        profile.prefs.setBool(false, forKey: PrefsKeys.Summarizer.summarizeContentFeature)

        XCTAssertFalse(subject.isShakeGestureEnabled)
    }

    func test_isShakeGestureEnabled_whenFeatureFlagDisabled() {
        let subject = createSubject()
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.shakeGestureEnabled)
        setIsAppleIntelligenceAvailable(isEnabled: false)
        setHostedSummarizerFeature(shakeGesture: false)

        XCTAssertFalse(subject.isShakeGestureEnabled)
    }

    func test_isShakeGestureEnabled_whenShakeGestureUserSettingDisabled() {
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
        let subject = createSubject(currentLocale: itTestLocale)
        setLanguageExpansionFeature(isEnabled: false)

        XCTAssertFalse(subject.isAppleSummarizerEnabled())
    }

    func test_isAppleSummarizerEnabled_whenLangExpansionDisabledAndAppleIntelligenceDisabled() {
        let subject = createSubject(currentLocale: itTestLocale)
        setLanguageExpansionFeature(isEnabled: false)
        setIsAppleIntelligenceAvailable(isEnabled: false)
        XCTAssertFalse(subject.isAppleSummarizerEnabled())
    }

    func test_isAppleSummarizerEnabled_whenLangExpansionEnabledAndLocaleNotEn() {
        let subject = createSubject(currentLocale: itTestLocale)

        XCTAssertTrue(subject.isAppleSummarizerEnabled())
    }

    // MARK: - isHostedSummarizerEnabled
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

    // MARK: - isAppAuthAttestEnabled
    func test_isAppAuthAttestEnabled_whenFeatureFlagEnabled() {
        let subject = createSubject()

        XCTAssertTrue(subject.isAppAttestAuthEnabled())
    }

    func test_isAppAuthAttestEnabled_whenFeatureFlagDisabled() {
        let subject = createSubject()
        setIsAppAttestAuthEnabled(isEnabled: false)

        XCTAssertFalse(subject.isAppAttestAuthEnabled())
    }

    // MARK: - isShakeGestureFeatureFlagEnabled
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
        let testLocales = ["en-US", "zh-Latn-HK"]
        setLanguageExpansionFeature(
            isEnabled: false,
            supportedLocaleIdentifiers: testLocales
        )

        let config = subject.languageExpansionConfiguration()

        XCTAssertFalse(config.isFeatureEnabled)
        XCTAssertEqual(config.supportedLocales.count, testLocales.count)
        XCTAssertEqual(config.supportedLocales[0].identifier, testLocales[0])
        XCTAssertEqual(config.supportedLocales[1].identifier, testLocales[1])
    }

    // MARK: - Helpers
    private func createSubject(
        currentLocale: Locale = Locale(identifier: "en")
    ) -> DefaultSummarizerNimbusUtils {
        return DefaultSummarizerNimbusUtils(
            profile: profile,
            localeProvider: MockLocaleProvider(current: currentLocale),
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

    private func setIsAppAttestAuthEnabled(isEnabled: Bool = true) {
        FxNimbus.shared.features.summarizerAppAttestAuthFeature.with { _, _ in
            return SummarizerAppAttestAuthFeature(enabled: isEnabled)
        }
    }

    private func setLanguageExpansionFeature(
        isEnabled: Bool = true,
        supportedLocaleIdentifiers: [String] = []
    ) {
        FxNimbus.shared.features.summarizerLanguageExpansionFeature.with { _, _ in
            return SummarizerLanguageExpansionFeature(
                enabled: isEnabled,
                supportedLocales: supportedLocaleIdentifiers
            )
        }
    }
}
