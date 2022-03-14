/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation


struct WhatsNewEventsHandler {
    
    //TODO: check which should be the logic of implementation
    var shouldShowWhatsNewButton: Bool {
        UserDefaults.standard.integer(forKey: OnboardingConstants.whatsNewCounter) != 0
    }
    
    func didShowWhatsNewButton() {
        UserDefaults.standard.set(AppInfo.shortVersion, forKey: OnboardingConstants.whatsNewVersion)
        UserDefaults.standard.removeObject(forKey: OnboardingConstants.whatsNewCounter)
    }
    
    func highlightWhatsNewButton() {
        let onboardingDidAppear = UserDefaults.standard.bool(forKey: OnboardingConstants.onboardingDidAppear)
        
        // Don't highlight whats new on a fresh install (onboardingDidAppear == false on a fresh install)
        if let lastShownWhatsNew = UserDefaults.standard.string(forKey: OnboardingConstants.whatsNewVersion)?.first, let currentMajorRelease = AppInfo.shortVersion.first {
            if onboardingDidAppear && lastShownWhatsNew != currentMajorRelease {
                setupWhatsNewFeature()
            }
        }
    }
    
    private func setupWhatsNewFeature () {
        let counter = UserDefaults.standard.integer(forKey: OnboardingConstants.whatsNewCounter)
        switch counter {
        case 4:
            // Shown three times, remove counter
            UserDefaults.standard.set(AppInfo.shortVersion, forKey: OnboardingConstants.whatsNewVersion)
            UserDefaults.standard.removeObject(forKey: OnboardingConstants.whatsNewCounter)
        default:
            // Show highlight
            UserDefaults.standard.set(counter+1, forKey: OnboardingConstants.whatsNewCounter)
        }
    }
}
