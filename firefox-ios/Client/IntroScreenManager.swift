// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import OnboardingKit

protocol IntroScreenManagerProtocol {
    var shouldShowIntroScreen: Bool { get }
    var isModernOnboardingEnabled: Bool { get }
    var onboardingVariant: OnboardingVariant { get }
    var onboardingKitVariant: OnboardingKit.OnboardingVariant { get }
    func didSeeIntroScreen()
}

struct IntroScreenManager: FeatureFlaggable, IntroScreenManagerProtocol {
    var prefs: Prefs

    var shouldShowIntroScreen: Bool {
        prefs.intForKey(PrefsKeys.IntroSeen) == nil
    }

    func didSeeIntroScreen() {
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
    }

    var isModernOnboardingEnabled: Bool {
        featureFlags.isFeatureEnabled(.modernOnboardingUI, checking: .buildAndUser)
    }

    var shouldUseBrandRefreshConfiguration: Bool {
        featureFlags.isFeatureEnabled(.shouldUseBrandRefreshConfiguration, checking: .buildAndUser)
    }

    var shouldUseJapanConfiguration: Bool {
        featureFlags.isFeatureEnabled(.shouldUseJapanConfiguration, checking: .buildAndUser)
    }

    /// Determines the onboarding variant based on feature flags.
    ///
    /// Priority order (if multiple flags are enabled):
    /// 1. Japan configuration (highest priority)
    /// 2. Brand refresh configuration
    /// 3. Modern onboarding
    /// 4. Legacy onboarding (lowest priority)
    ///
    /// Note: If both `shouldUseJapanConfiguration` and `shouldUseBrandRefreshConfiguration`
    /// are enabled, Japan configuration takes precedence.
    var onboardingVariant: OnboardingVariant {
        if isModernOnboardingEnabled && shouldUseJapanConfiguration {
            return .japan
        } else if isModernOnboardingEnabled && shouldUseBrandRefreshConfiguration {
            return .brandRefresh
        } else if isModernOnboardingEnabled {
            return .modern
        } else {
            return .legacy
        }
    }

    /// Returns the OnboardingKit variant corresponding to the onboarding variant.
    /// This avoids duplication of conversion logic across the codebase.
    var onboardingKitVariant: OnboardingKit.OnboardingVariant {
        return OnboardingKit.OnboardingVariant(rawValue: onboardingVariant.rawValue) ?? .modern
    }
}
