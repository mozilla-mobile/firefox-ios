// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class LegacyOnboardingTests: FeatureFlaggedTestSuite {
    // We just test the legacy onboarding flow in this file.
    let flowType = OnboardingScreen.OnboardingFlowType.legacy

    var onboardingScreen: OnboardingScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!

    override func setUpExperimentVariables() {
        jsonFileName = flowType.jsonFeatureOverrideFileName
        featureName = flowType.onboardingFeatureName

        launchArguments = [
            LaunchArguments.ClearProfile,
            LaunchArguments.DisableAnimations,
            LaunchArguments.ResetDefaultBrowserStatus
        ]
    }

    override func setUp() async throws {
        try await super.setUp()

        onboardingScreen = OnboardingScreen(app: app, flowType: flowType)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)

        // Launch the app so we can detect UI elements and decide whether to run these tests.
        launchApp()

        // If the legacy "Agree and Continue" button is not present, skip the entire class.
        let agreeButton = onboardingScreen.agreeAndContinueButton()
        if !agreeButton.mozWaitForElementToExist(timeout: 4, failOnTimeout: false) {
            throw XCTSkip("Skipping LegacyOnboardingTests because legacy" +
                          " 'Agree and Continue' button not found (not running legacy flow)")
        }
    }

    override func tearDown() async throws {
        app.terminate()
        try await super.tearDown()
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2306816
    func testLegacyOnboardingCloseTour() {
        onboardingScreen.handleTermsOfService()
        onboardingScreen.closeTourIfNeeded()

        firefoxHomePageScreen.dismissNewChangesPopupIfNeeded()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }

    // MARK: Skipping Onboarding with Close Button
    // https://mozilla.testrail.io/index.php?/cases/view/2575177
    func testLegacyOnboardingCloseOptionLastCard() throws {
        onboardingScreen.handleTermsOfService()

        // Wait for the initial title label to appear
        onboardingScreen.assertTitle()

        // Go to second screen
        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.assertTitle()

        // Go to third screen
        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.assertTitle()

        // Go to fourth screen
        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.assertTitle()

        if !iPad() {
            // Go to fifth (last) screen
            onboardingScreen.goToNextScreenViaPrimary()
            onboardingScreen.assertTitle()
        }

        // Test closing the tour at the very last card using the X
        onboardingScreen.closeTour()

        firefoxHomePageScreen.assertTopSitesItemCellExist()
    }
}
