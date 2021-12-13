// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import StoreKit
import Shared

class RatingPromptManager {

    private let profile: Profile
    private var hasAtLeastFiveBookmarks = false
    private var hasAtLeastTwoPinnedShortcuts = false

    private enum UserDefaultsKey: String {
        case keyIsBrowserDefault = "com.moz.isBrowserDefault.key"
        case keyRatingPromptLastRequestDate = "com.moz.ratingPromptLastRequestDate.key"
        case keyRatingPromptRequestCount = "com.moz.ratingPromptRequestCount.key"
    }

    init(profile: Profile) {
        self.profile = profile
        updateData()
    }

    func showRatingPromptIfNeeded() {
        if shouldShowPrompt {
            lastRequestDate = Date()
            SKStoreReviewController.requestReview()
        }
    }

    // TODO: Add settings RatingsPrompt.Settings.RateOnAppStore
    func goToAppStore() {
        guard let url = URL(string: "https://itunes.apple.com/app/id\(AppInfo.appStoreId)?action=write-review") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: UserDefaults

    static var isBrowserDefault: Bool {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyIsBrowserDefault.rawValue) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyIsBrowserDefault.rawValue) }
    }

    private var lastRequestDate: Date? {
        get { return Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue)) }
        set { UserDefaults.standard.set(newValue?.timeIntervalSince1970, forKey: UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue) }
    }

    private var requestCount: Int {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyRatingPromptRequestCount.rawValue) as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyRatingPromptRequestCount.rawValue) }
    }

    func reset() {
        RatingPromptManager.isBrowserDefault = false
        lastRequestDate = nil
        requestCount = 0
    }

    // MARK: Private

    private var shouldShowPrompt: Bool {
        // Required: 5th launch or more
        let currentSessionCount = profile.prefs.intForKey(PrefsKeys.SessionCount) ?? 0
        guard currentSessionCount >= 5 else { return false }

        // Required: 5 consecutive days of use in the last 7 days
        guard hasFiveConsecutiveDaysOfUse else { return false }

        // One of the followings
        let isBrowserDefault = RatingPromptManager.isBrowserDefault
        let hasSyncAccount = profile.hasSyncableAccount()
        let engineIsGoogle = profile.searchEngines.defaultEngine.shortName == "Google"
        let hasTPStrict = profile.prefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap({BlockingStrength(rawValue: $0)}) == .strict
        guard isBrowserDefault || hasSyncAccount || hasAtLeastFiveBookmarks || hasAtLeastTwoPinnedShortcuts || !engineIsGoogle || hasTPStrict else { return false }

        // Ensure we ask again only if 2 weeks has passed
        guard !hasRequestedInTheLastTwoWeeks else { return false }

        // Only ask once for now once the triggers are fulfilled
        // Keep in mind, second and third time will be asked at a later point with other stories. We can ask three times per period of 365 days.
        guard hasAskedOnce else { return false }

        return true
    }

    private func updateData() {
        // TODO: hasAtLeastFiveBookmarks
        // TODO: hasAtLeastTwoPinnedShortcuts
    }

    private var hasFiveConsecutiveDaysOfUse: Bool {
        // TODO: Count the days
        return false
    }

    private var hasRequestedInTheLastTwoWeeks: Bool {
        // TODO: hasRequestedInTheLastTwoWeeks
        return false
    }

    private var hasAskedOnce: Bool {
        // TODO: hasAskedOnce
        return false
    }
}
