// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

enum InstallType: String, Codable {
    case fresh
    case upgrade
    case unknown
    
    // Helper methods
    static func get() -> InstallType {
        guard let rawValue = UserDefaults.standard.string(forKey: PrefsKeys.InstallType), let type = InstallType(rawValue: rawValue) else {
            return unknown
        }
        return type
    }
    
    static func set(type: InstallType) {
        UserDefaults.standard.set(type.rawValue, forKey: PrefsKeys.InstallType)
    }
    
    static func persistedCurrentVersion() -> String {
        guard let currentVersion = UserDefaults.standard.string(forKey: PrefsKeys.KeyCurrentInstallVersion) else {
            return ""
        }
        return currentVersion
    }
    
    static func updateCurrentVersion(version: String) {
        UserDefaults.standard.set(version, forKey: PrefsKeys.KeyCurrentInstallVersion)
    }
}

// Data Model
struct DefaultBrowserOnboardingModel {
    var titleText: String
    var descriptionText: [String]
    var imageText: String
}

class DefaultBrowserOnboardingViewModel {

    var goToSettings: (() -> Void)?
    var model: DefaultBrowserOnboardingModel?

    private static let maxSessionCount = 3

    init() {
        setupModel()
    }
    
    private func setupModel() {
        model = DefaultBrowserOnboardingModel(
            titleText: String.DefaultBrowserCardTitle,
            descriptionText: descriptionText,
            imageText: String.DefaultBrowserOnboardingScreenshot
        )
    }

    private var descriptionText: [String] {
        [String.DefaultBrowserCardDescription,
         String.DefaultBrowserOnboardingDescriptionStep1,
         String.DefaultBrowserOnboardingDescriptionStep2,
         String.DefaultBrowserOnboardingDescriptionStep3]
    }
    
    static func shouldShowDefaultBrowserOnboarding(userPrefs: Prefs) -> Bool {
        // Only show on fresh install
        guard InstallType.get() == .fresh else { return false }

        let didShow = UserDefaults.standard.bool(forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
        guard !didShow else { return false }

        var shouldShow = false
        // Get the session count from preferences
        let currentSessionCount = userPrefs.intForKey(PrefsKeys.SessionCount) ?? 0
        if currentSessionCount == DefaultBrowserOnboardingViewModel.maxSessionCount {
            shouldShow = true
            UserDefaults.standard.set(true, forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
        }

        return shouldShow
    }
}
