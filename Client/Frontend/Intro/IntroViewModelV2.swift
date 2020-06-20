/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ViewControllerConsts {
    struct PreferredSize {
        static let IntroViewController = CGSize(width: 375, height: 667)
        static let UpdateViewController = CGSize(width: 375, height: 667)
    }
}

protocol CardTheme {
    var theme: BuiltinThemeName { get }
}

extension CardTheme {
    var theme: BuiltinThemeName {
        return BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
    }
}

// MARK: Requires Work (Currently part of A/B test)
// Intro View Model V2 - This is suppose to be the main view model for the
// IntroView V2 however since we are running an onboarding A/B test
// and there might be a chance that some of the work related to views
// might be throw away hence keeping it super simple for IntroViewControllerV2
// This is another reason why we don't have a proper model either.

class IntroViewModelV2 {
    // Internal vars
    var screenType: OnboardingScreenType?
    // private vars
    private var onboardingResearch: OnboardingUserResearch?
    
    // Initializer
    init() {
        onboardingResearch = OnboardingUserResearch()
        // Case: Older user who has updated to a newer version and is not a first time user
        // When user updates from a version of app which didn't have the
        // user research onboarding screen type and is trying to Always Show the screen
        // from Show Tour, we default to our .version1 of the screen
        screenType = onboardingResearch?.onboardingScreenType ?? .versionV1
    }
}
