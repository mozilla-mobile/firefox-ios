// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

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
        if #available(iOS 17.0, *) {
            switchThemeToDarkOrLight(theme: "Light")
        }
        app.terminate()
        super.tearDown()
    }

    func testA11yFirstRunTour() throws {
        // swiftlint:disable large_tuple
        var missingLabels: [(elementType: String, identifier: String)] = []
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
        let buttons = app.buttons.allElementsBoundByIndex
        // let texts = app.staticTexts.allElementsBoundByIndex
        // let pageIndicators = app.pageIndicators.allElementsBoundByIndex

        for button in buttons {
            if button.accessibilityLabel == nil || button.accessibilityLabel!.isEmpty {
                missingLabels.append((elementType: "Button", identifier: button.identifier))
            }
        }

        if missingLabels.isEmpty {
            print("All elements have accessibility labels 🎉")
        } else {
            print("Accessibility Report: Missing Labels")
            for (index, element) in missingLabels.enumerated() {
                 print("\(index + 1). Type: \(element.elementType), Identifier: \(element.identifier)")
            }
        }

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

        // Swipe to the third screen
        app.buttons["\(rootA11yId)SecondaryButton"].waitAndTap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"])
        try app.performAccessibilityAudit()

        // Swipe to the fourth screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        try app.performAccessibilityAudit()

        // Swipe to the fifth screen
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        currentScreen += 1
        mozWaitForElementToExist(app.images["\(rootA11yId)ImageView"], timeout: TIMEOUT)
        try app.performAccessibilityAudit()

        // Finish onboarding
        app.buttons["\(rootA11yId)PrimaryButton"].tap()
        let topSites = app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        mozWaitForElementToExist(topSites)
    }
}
