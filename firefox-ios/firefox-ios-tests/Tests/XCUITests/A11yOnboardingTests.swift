// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class A11yOnboardingTests: BaseTestCase {
    var currentScreen = 0
    var rootA11yId: String {
        return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)"
    }

    override func setUp() {
        launchArguments = [LaunchArguments.ClearProfile,
                           LaunchArguments.DisableAnimations,
                           LaunchArguments.SkipSplashScreenExperiment]
        currentScreen = 0
        super.setUp()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testA11yFirstRunTour() throws {
        let sanitizedTestName = self.name.replacingOccurrences(of: "()", with: "").replacingOccurrences(of: ".", with: "_")
        // swiftlint:disable large_tuple
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        // swiftlint:enable large_tuple
        guard #available(iOS 17.0, *), !skipPlatform else { return }

        // Complete the First run from first screen to the latest one
        // Check that the first's tour screen is shown as well as all the elements in there
        waitForElementsToExist(
            [
                app.images["\(rootA11yId)ImageView"],
                app.staticTexts["\(rootA11yId)TitleLabel"],
                app.staticTexts["\(rootA11yId)DescriptionLabel"],
                app.buttons["\(rootA11yId)PrimaryButton"],
                app.buttons["\(rootA11yId)SecondaryButton"],
                app.buttons["\(AccessibilityIdentifiers.Onboarding.closeButton)"],
                app.pageIndicators["\(AccessibilityIdentifiers.Onboarding.pageControl)"]
            ]
        )
        try app.performAccessibilityAudit()
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

        // Swipe to the second screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForElementsToExist(
            [
                app.images["\(rootA11yId)ImageView"],
                app.staticTexts["\(rootA11yId)TitleLabel"],
                app.staticTexts["\(rootA11yId)DescriptionLabel"],
                app.buttons["\(rootA11yId)PrimaryButton"],
            ]
        )
        try app.performAccessibilityAudit()
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

        // Swipe to the third screen
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"])
        try app.performAccessibilityAudit()
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

        // Swipe to the fourth screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        try app.performAccessibilityAudit()
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

        // Swipe to the fifth screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        try app.performAccessibilityAudit()
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

        // Finish onboarding
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        let topSites = app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)

        // Generate Report
        A11yUtils.generateAndAttachReport(missingLabels: missingLabels, testName: sanitizedTestName, generateCsv: false)
    }
}
