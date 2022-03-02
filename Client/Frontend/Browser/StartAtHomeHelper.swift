// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class StartAtHomeHelper: FeatureFlagsProtocol {
    private var isRestoringTabs: Bool
    // Override only for unit test to test `shouldSkipStartHome` logic
    private var isRunningTest: Bool
    lazy var startAtHomeSetting: StartAtHomeSetting? = featureFlags.userPreferenceFor(.startAtHome)
    
    init(isRestoringTabs: Bool,
         isRunnigTest: Bool = AppConstants.IsRunningTest) {
        self.isRestoringTabs = isRestoringTabs
        self.isRunningTest = isRunnigTest
    }
    
    var shouldSkipStartHome: Bool {
        return isRunningTest ||
              DebugSettingsBundleOptions.skipSessionRestore ||
              isRestoringTabs
    }

    /// Determines whether the Start at Home feature is enabled, how long it has been since
    /// the user's last activity and whether, based on their settings, Start at Home feature
    /// should perform its function.
    public func shouldStartAtHome() -> Bool {
        guard featureFlags.isFeatureActiveForBuild(.startAtHome),
              let setting = startAtHomeSetting,
              setting != .disabled
        else { return false }

        let lastActiveTimestamp = UserDefaults.standard.object(forKey: "LastActiveTimestamp") as? Date ?? Date()
        let dateComponents = Calendar.current.dateComponents([.hour, .second],
                                                             from: lastActiveTimestamp,
                                                             to: Date())
        var timeSinceLastActivity = 0
        var timeToOpenNewHome = 0

        if setting == .afterFourHours {
            timeSinceLastActivity = dateComponents.hour ?? 0
            timeToOpenNewHome = 4
        } else if setting == .always {
            timeSinceLastActivity = dateComponents.second ?? 0
            timeToOpenNewHome = 5
        }

        return timeSinceLastActivity >= timeToOpenNewHome
    }

    /// Looks to see if the user already has a homepage tab open (as per their preferences)
    /// and, if they do, returns that tab, in order to avoid opening multiple duplicate
    /// homepage tabs.
    ///
    /// - Parameters:
    ///   - tabs: The tabs to be scanned, either private, or normal, based on the last session
    ///   - profilePreferences: Preferences stored in the user's `Profile`
    /// - Returns: An optional tab, that matches the user's new tab preferences.
    public func scanForExistingHomeTab(in tabs: [Tab],
                                       with profilePreferences: Prefs) -> Tab? {
        let pagePreferences = NewTabAccessors.getHomePage(profilePreferences)

        switch pagePreferences {
        case .homePage:
            return tabs.first { $0.isCustomHomeTab }
        case .topSites:
            return tabs.first { $0.isFxHomeTab }
        case .blankPage:
            return nil
        }
    }
}
