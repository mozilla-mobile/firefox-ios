/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Data Model
struct DefaultBrowserOnboardingModel {
    var titleImage: UIImage
    var titleText: String
    var descriptionText: [String]
    var imageText: String
}

class DefaultBrowserOnboardingViewModel {
    //  Internal vars
    var model: DefaultBrowserOnboardingModel?
    var goToSettings: (() -> Void)?
    
    init() {
        setupUpdateModel()
    }

    private func getCorrectImage() -> UIImage {
        let layoutDirection = UIApplication.shared.userInterfaceLayoutDirection
        switch ThemeManager.instance.currentName {
        case .dark:
            if layoutDirection == .leftToRight {
                return UIImage(named: "Dark-LTR")!
            } else {
                return UIImage(named: "Dark-RTL")!
            }
        case .normal:
            if layoutDirection == .leftToRight {
                return UIImage(named: "Light-LTR")!
            } else {
                return UIImage(named: "Light-RTL")!
            }
        }
    }
    
    private func setupUpdateModel() {
        model = DefaultBrowserOnboardingModel(titleImage: getCorrectImage(), titleText: String.DefaultBrowserCardTitle, descriptionText: [String.DefaultBrowserCardDescription, String.DefaultBrowserOnboardingDescriptionStep1, String.DefaultBrowserOnboardingDescriptionStep2, String.DefaultBrowserOnboardingDescriptionStep3], imageText: String.DefaultBrowserOnboardingScreenshot)
    }
    
    static func shouldShowDefaultBrowserOnboarding(userPrefs: Prefs) -> Bool {
        // 0,1,2 so we show on 3rd session as a requirement
        let maxSessionCount = 2
        var shouldShow = false
        // Session count
        var sessionCount: Int32 = 0
        
        // Get the session count from preferences
        if let currentSessionCount = userPrefs.intForKey(PrefsKeys.KeyDefaultBrowserCardSessionCount) {
            sessionCount = currentSessionCount
        }

        // increase session count value
        if sessionCount < maxSessionCount && sessionCount != -1 {
            userPrefs.setInt(sessionCount + 1, forKey: PrefsKeys.KeyDefaultBrowserCardSessionCount)
        // reached max count, show card
        } else if sessionCount == maxSessionCount {
            userPrefs.setInt(-1, forKey: PrefsKeys.KeyDefaultBrowserCardSessionCount)
            shouldShow = true
        }

        return shouldShow
    }
}
