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
    
    // Used for theme changes
    func refreshModelImage() {
        model?.titleImage = getCorrectImage()
    }
    
    static func shouldShowDefaultBrowserOnboarding(userPrefs: Prefs) -> Bool {
        // Show on 3rd session
        let maxSessionCount = 3
        var shouldShow = false
        // Get the session count from preferences
        let currentSessionCount = userPrefs.intForKey(PrefsKeys.SessionCount) ?? 0
        let didShow = UserDefaults.standard.bool(forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
        guard !didShow else { return false }
        
        if currentSessionCount == maxSessionCount {
            shouldShow = true
            UserDefaults.standard.set(true, forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
        }

        return shouldShow
    }
}
