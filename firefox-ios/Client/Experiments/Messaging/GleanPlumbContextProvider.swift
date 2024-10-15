// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

class GleanPlumbContextProvider {
    enum ContextKey: String {
        case todayDate = "date_string"
        case isDefaultBrowser = "is_default_browser"
        case isInactiveNewUser = "is_inactive_new_user"
        case allowedTipsNotifications = "allowed_tips_notifications"
        case numberOfAppLaunches = "number_of_app_launches"
        case numberOfSyncedDevices = "number_of_sync_devices"
        case signedInFxaAccount = "is_fxa_signed_in"
    }

    struct Constant {
        static let activityReferencePeriod = UInt64(60 * 60 * 48 * 1000) // 48 hours in milliseconds
        static let inactivityPeriod = UInt64(60 * 60 * 24 * 1000) // 24 hours in milliseconds
    }

    var userDefaults: UserDefaultsInterface = UserDefaults.standard
    private var profile: Profile

    init(profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile
    }

    private var todaysDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        return dateFormatter.string(from: Date())
    }

    private var isDefaultBrowser: Bool {
        return userDefaults.bool(forKey: RatingPromptManager.UserDefaultsKey.keyIsBrowserDefault.rawValue)
    }

    private var numberOfAppLaunches: Int32 {
        return profile.prefs.intForKey(PrefsKeys.Session.Count) ?? 0
    }

    private var numberOfSyncedDevices: Int32 {
        return profile.prefs.intForKey(PrefsKeys.Sync.numberOfSyncedDevices) ?? 0
    }

    private var signedInFxaAccount: Bool {
        return profile.prefs.boolForKey(PrefsKeys.Sync.signedInFxaAccount) ?? false
    }

    var isInactiveNewUser: Bool {
        // existing users don't have firstAppUse set
        guard let firstAppUse = userDefaults.object(forKey: PrefsKeys.Session.FirstAppUse) as? UInt64,
              let lastSession = userDefaults.object(forKey: PrefsKeys.Session.Last) as? UInt64
        else { return false }

        // We check that it's 48 hours after first use and that the user only used the app in the first 24 hours
        // It doesn't matter how often the user is active in the first 24 hours of the 48 hour period.
        // If they are not active in the second 24 hours after first use they are considered inactive.
        let now = Date()
        let lastSessionDate = Date.fromTimestamp(lastSession)
        let isAfter48Hours = now >= Date.fromTimestamp(firstAppUse + Constant.activityReferencePeriod)
        let usedInTheFirst24Hours = lastSessionDate <= Date.fromTimestamp(firstAppUse + Constant.inactivityPeriod)

        return isAfter48Hours && usedInTheFirst24Hours
    }

    private var allowedTipsNotifications: Bool {
        let userPreference = userDefaults.bool(forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
        return userPreference
    }

    /// JEXLs are more accurately evaluated when given certain details about the app on device.
    /// There is a limited amount of context you can give. See:
    /// - https://experimenter.info/mobile-messaging/#list-of-attributes
    /// We should pass as much device context as possible.
    func createAdditionalDeviceContext() -> [String: Any] {
        return [ContextKey.todayDate.rawValue: todaysDate,
                ContextKey.isDefaultBrowser.rawValue: isDefaultBrowser,
                ContextKey.isInactiveNewUser.rawValue: isInactiveNewUser,
                ContextKey.numberOfAppLaunches.rawValue: numberOfAppLaunches,
                ContextKey.numberOfSyncedDevices.rawValue: numberOfSyncedDevices,
                ContextKey.allowedTipsNotifications.rawValue: allowedTipsNotifications,
                ContextKey.signedInFxaAccount.rawValue: signedInFxaAccount
        ]
    }
}
