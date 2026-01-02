// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest
import MozillaAppServices
import OnboardingKit

@testable import Client

final class IntroScreenManagerTests: XCTestCase {
    var prefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
        let mockProfile = MockProfile(databasePrefix: "IntroScreenManagerTests_")
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        prefs = nil
        super.tearDown()
    }

    // MARK: - shouldShowIntroScreen Tests

    func testHasntSeenIntroScreenYet_shouldShowIt() {
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.shouldShowIntroScreen)
    }

    func testHasSeenIntroScreen_shouldNotShowIt() {
        let subject = IntroScreenManager(prefs: prefs)
        subject.didSeeIntroScreen()
        XCTAssertFalse(subject.shouldShowIntroScreen)
    }

    func testIntroScreenPrefSetToNonNilValue_shouldNotShowIt() {
        // Set pref to a value other than nil (simulating it was seen)
        prefs.setInt(0, forKey: PrefsKeys.IntroSeen)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertFalse(subject.shouldShowIntroScreen)
    }

    // MARK: - didSeeIntroScreen Tests

    func testDidSeeIntroScreen_setsPrefValue() {
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertNil(prefs.intForKey(PrefsKeys.IntroSeen))

        subject.didSeeIntroScreen()

        XCTAssertEqual(prefs.intForKey(PrefsKeys.IntroSeen), 1)
    }

    // MARK: - isModernOnboardingEnabled Tests

    func testIsModernOnboardingEnabled_whenFeatureFlagDisabled_returnsFalse() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertFalse(subject.isModernOnboardingEnabled)
    }

    func testIsModernOnboardingEnabled_whenFeatureFlagEnabled_returnsTrue() {
        setupNimbusFeatureFlags(enableModernUi: true, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.isModernOnboardingEnabled)
    }

    // MARK: - shouldUseJapanConfiguration Tests

    func testShouldUseJapanConfiguration_whenFeatureFlagDisabled_returnsFalse() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertFalse(subject.shouldUseJapanConfiguration)
    }

    func testShouldUseJapanConfiguration_whenFeatureFlagEnabled_returnsTrue() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: true)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.shouldUseJapanConfiguration)
    }

    // MARK: - onboardingVariant Tests

    func testOnboardingVariant_whenBothFlagsDisabled_returnsLegacy() {
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertEqual(subject.onboardingVariant, .legacy)
    }

    func testOnboardingVariant_whenModernEnabledButJapanDisabled_returnsModern() {
        setupNimbusFeatureFlags(enableModernUi: true, shouldUseJapanConfiguration: false)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertEqual(subject.onboardingVariant, .modern)
    }

    func testOnboardingVariant_whenBothFlagsEnabled_returnsJapan() {
        setupNimbusFeatureFlags(enableModernUi: true, shouldUseJapanConfiguration: true)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertEqual(subject.onboardingVariant, .japan)
    }

    func testOnboardingVariant_whenModernDisabledButJapanEnabled_returnsLegacy() {
        // Japan configuration requires modern UI to be enabled
        setupNimbusFeatureFlags(enableModernUi: false, shouldUseJapanConfiguration: true)
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertEqual(subject.onboardingVariant, .legacy)
    }

    // MARK: - Helper Methods

    private func setupNimbusFeatureFlags(enableModernUi: Bool, shouldUseJapanConfiguration: Bool) {
        FxNimbus.shared.features.onboardingFrameworkFeature.with { appContext, _ in
            OnboardingFrameworkFeature(
                appContext,
                UserDefaults.standard,
                cards: [:],
                conditions: ["ALWAYS": "true"],
                dismissable: false,
                enableModernUi: enableModernUi,
                shouldUseJapanConfiguration: shouldUseJapanConfiguration
            )
        }
    }
}
