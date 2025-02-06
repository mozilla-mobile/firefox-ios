// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
@testable import Client

final class OnboardingTests: SnapshotBaseTests {

    func testWelcomeScreen() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            Welcome(delegate: MockWelcomeDelegate(), windowUUID: .snapshotTestDefaultUUID)
        }, wait: 1.0)
    }

    func testWelcomeStepsScreens() {
        // Number of steps in the WelcomeTour
        let numberOfSteps = 4
        // Iterate through steps and take snapshots, skipping the first one
        for step in 1...numberOfSteps {
            let startingStep = WelcomeTour.Step.all[step-1]
            /*
             Precision at .95 to accommodate a snapshot looking slightly different 
             due to the different data output from the statistics json
             as well as the fact that is not possible to update the Locale.current
             hence the component depending on it will show the decimal divider 
             in the current language.
             */
            SnapshotTestHelper.assertSnapshot(initializingWith: {
                WelcomeTour(delegate: MockWelcomeTourDelegate(), windowUUID: .snapshotTestDefaultUUID, startingStep: startingStep)
            },
                                              wait: 1.0,
                                              precision: 0.95,
                                              testName: "testWelcomeScreen_step_\(step)")
        }
    }
}
