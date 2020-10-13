/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Leanplum
import Shared

struct LPVariables {
    // Variable Used for AA test
    static var showOnboardingScreenAA = LPVar.define("showOnboardingScreen", with: true)
    // Variable Used for AB test
    static var showOnboardingScreenAB = LPVar.define("showOnboardingScreen_2", with: true)
    // Variable Used for 2nd Iteration of Onboarding AB Test
    static var onboardingABTestV2 = LPVar.define("onboardingABTestV2", with: true)
    // Variable Used for New Tab Button AB Test
    static var newTabButtonABTest = LPVar.define("newTabButtonABTestProd", with: false)
}
