/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation


class WhatsNewEventsHandler {
    
    @Published public var shouldShowWhatsNew: Bool = false
    
    func didShowWhatsNew() {
        UserDefaults.standard.set(AppInfo.shortVersion, forKey: OnboardingConstants.whatsNewVersion)
        shouldShowWhatsNew = false
    }
    
    func highlightWhatsNewButton() {
        
        // Don't highlight whats new on a fresh install, highlight on every release of the app
        if let lastShownWhatsNew = UserDefaults.standard.string(forKey: OnboardingConstants.whatsNewVersion) {
            shouldShowWhatsNew = (lastShownWhatsNew != AppInfo.shortVersion)
        } else {
            UserDefaults.standard.set(AppInfo.shortVersion, forKey: OnboardingConstants.whatsNewVersion)
        }
    }
}
