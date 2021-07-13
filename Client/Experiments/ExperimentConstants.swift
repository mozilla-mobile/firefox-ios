/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// An application specific enum of app features that we are configuring
/// with experiments. Despite being named `NimbusFeatureID`, what we are
/// considering features here, are considered experiments in Nimbus.
/// This is expected to grow and shrink across releases of the app.
enum NimbusFeatureId: String {
    case nimbusValidation = "nimbus-validation"
    case onboardingDefaultBrowser = "onboarding-default-browser"
    case inactiveTabs = "inactiveTabs"
}

/// A set of common branch ids used in experiments. Branch ids can be application/experiment specific, so
/// _could_ be an `enum`; however, there is a likelihood that they will become less relevant in the future.
enum NimbusExperimentBranch {
    static let a1 = "a1"
    static let a2 = "a2"
    static let control = "control"
    static let treatment = "treatment"
    static let defaultBrowserTreatment = "defaultBrowserTreatment"

    enum InactiveTab {
        static let control = "inactiveTabControl"
        static let treatment = "inactiveTabTreatment"
    }
}
