// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class A11yOnboardingTests: BaseTestCase {
    private var onboardingScreen: OnboardingScreen!
    private var firefoxHomePageScreen: FirefoxHomePageScreen!

    private var rootA11yId: String { onboardingScreen.rootA11yId }

    override func setUp() async throws {
        launchArguments = [LaunchArguments.ClearProfile,
                           LaunchArguments.DisableAnimations,
                           LaunchArguments.SkipSplashScreenExperiment]
        try await super.setUp()
        onboardingScreen = OnboardingScreen(app: app, flowType: .legacy)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
    }

    override func tearDown() async throws {
        app.terminate()
        try await super.tearDown()
    }

    func testA11yFirstRunTour() throws {
        let sanitizedTestName = self.name.replacingOccurrences(of: "()", with: "").replacingOccurrences(of: ".", with: "_")
        // swiftlint:disable large_tuple
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        // swiftlint:enable large_tuple
        guard #available(iOS 17.0, *), !skipPlatform else { return }

        // Screen 0: first tour screen, including close button and page control
        onboardingScreen.waitForCurrentScreenElements(checkCloseButton: true, checkPageControl: true)
        try app.performAccessibilityAudit()
        checkMissingLabels(missingLabels: &missingLabels)

        // Swipe to the second screen
        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.waitForCurrentScreenElements()
        try app.performAccessibilityAudit()
        checkMissingLabels(missingLabels: &missingLabels)

        // Swipe to the third screen
        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.waitForCurrentScreenElements()
        try app.performAccessibilityAudit()
        checkMissingLabels(missingLabels: &missingLabels)

        // Swipe to the fourth screen
        onboardingScreen.goToNextScreenViaSecondary()
        onboardingScreen.waitForCurrentScreenElements()
        try app.performAccessibilityAudit()
        checkMissingLabels(missingLabels: &missingLabels)

        // Swipe to the fifth screen
        onboardingScreen.goToNextScreenViaPrimary()
        onboardingScreen.waitForCurrentScreenElements()
        try app.performAccessibilityAudit()
        checkMissingLabels(missingLabels: &missingLabels)

        // Finish onboarding
        onboardingScreen.goToNextScreenViaPrimary()
        firefoxHomePageScreen.assertTopSitesItemCellExist()

        // Generate Report
        A11yUtils.generateAndAttachReport(missingLabels: missingLabels, testName: sanitizedTestName, generateCsv: false)
    }

    private func checkMissingLabels(missingLabels: inout [A11yUtils.MissingAccessibilityElement]) {
        A11yUtils.checkMissingLabels(
            in: app.buttons.allElementsBoundByIndex,
            screenName: "Onboarding \(rootA11yId) Screen",
            missingLabels: &missingLabels,
            elementType: "Button"
        )
        A11yUtils.checkMissingLabels(
            in: app.images.allElementsBoundByIndex,
            screenName: "Onboarding \(rootA11yId) Screen",
            missingLabels: &missingLabels,
            elementType: "Image"
        )
        A11yUtils.checkMissingLabels(
            in: app.staticTexts.allElementsBoundByIndex,
            screenName: "Onboarding \(rootA11yId) Screen",
            missingLabels: &missingLabels,
            elementType: "StaticText"
        )
    }
}
