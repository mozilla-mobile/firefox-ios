// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

class StartAtHomeHelper: FeatureFlaggable {
    private var isRestoringTabs: Bool
    // Override only for UI tests to test `shouldSkipStartHome` logic
    private var isRunningUITest: Bool
    private let prefs: Prefs
    var launchSessionProvider: LaunchSessionProviderProtocol

    init(appSessionManager: AppSessionProvider = AppContainer.shared.resolve(),
         prefs: Prefs,
         isRestoringTabs: Bool,
         isRunningUITest: Bool = AppConstants.isRunningUITests
    ) {
        self.launchSessionProvider = appSessionManager.launchSessionProvider
        self.prefs = prefs
        self.isRestoringTabs = isRestoringTabs
        self.isRunningUITest = isRunningUITest
    }

    var shouldSkipStartHome: Bool {
        return isRunningUITest ||
        DebugSettingsBundleOptions.skipSessionRestore ||
        isRestoringTabs ||
        launchSessionProvider.openedFromExternalSource
    }

    var startAtHomeSetting: StartAtHomeSetting {
        get {
            if let prefs = prefs.stringForKey(PrefsKeys.UserFeatureFlagPrefs.StartAtHome) {
                return StartAtHomeSetting(rawValue: prefs) ?? .afterFourHours
            }
            return .afterFourHours
        }
        set { prefs.setString(newValue.rawValue, forKey: PrefsKeys.UserFeatureFlagPrefs.StartAtHome) }
    }

    /// Determines whether the Start at Home feature is enabled, how long it has been since
    /// the user's last activity and whether, based on their settings, Start at Home feature
    /// should perform its function.
    public func shouldStartAtHome() -> Bool {
        let setting = startAtHomeSetting

        let lastActiveTimestamp = UserDefaults.standard.object(forKey: "LastActiveTimestamp") as? Date ?? Date()
        let dateComponents = Calendar.current.dateComponents([.hour, .second],
                                                             from: lastActiveTimestamp,
                                                             to: Date())

        switch setting {
        case .afterFourHours:
            return dateComponents.hour ?? 9 >= 4
        case .always:
            return true
        case .disabled:
            return false
        }
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
