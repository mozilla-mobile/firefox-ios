// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import StoreKit
import Shared
import Storage

class RatingPromptManager {

    private let profile: Profile
    private let daysOfUseCounter: CumulativeDaysOfUseCounter

    private var hasMinimumBookmarksCount = false
    private let minimumBookmarksCount = 5

    private var hasMinimumPinnedShortcutsCount = false
    private let minimumPinnedShortcutsCount = 2

    private let dataQueue = DispatchQueue(label: "com.moz.ratingPromptManager.queue")

    private enum UserDefaultsKey: String {
        case keyIsBrowserDefault = "com.moz.isBrowserDefault.key"
        case keyRatingPromptLastRequestDate = "com.moz.ratingPromptLastRequestDate.key"
        case keyRatingPromptRequestCount = "com.moz.ratingPromptRequestCount.key"
    }

    init(profile: Profile, daysOfUseCounter: CumulativeDaysOfUseCounter) {
        self.profile = profile
        self.daysOfUseCounter = daysOfUseCounter

        updateData()
    }

    func showRatingPromptIfNeeded() {
        if shouldShowPrompt {
            lastRequestDate = Date()
            requestCount += 1

            SKStoreReviewController.requestReview()
        }
    }

    // TODO: Add settings RatingsPrompt.Settings.RateOnAppStore
    static func goToAppStoreReview() {
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
        guard daysOfUseCounter.hasRequiredCumulativeDaysOfUse else { return false }

        // One of the followings
        let isBrowserDefault = RatingPromptManager.isBrowserDefault
        let hasSyncAccount = profile.hasSyncableAccount()
        let engineIsGoogle = profile.searchEngines.defaultEngine.shortName == "Google"
        let hasTPStrict = profile.prefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap({BlockingStrength(rawValue: $0)}) == .strict
        guard isBrowserDefault || hasSyncAccount || hasMinimumBookmarksCount || hasMinimumPinnedShortcutsCount || !engineIsGoogle || hasTPStrict else { return false }

        // Ensure we ask again only if 2 weeks has passed
        guard !hasRequestedInTheLastTwoWeeks else { return false }

        // Only ask once for now once the triggers are fulfilled. We can ask three times per period of 365 days.
        // Second and third time will be asked at a later point with other stories.
        guard requestCount < 1 else { return false }

        return true
    }

    private func updateData() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.updateBookmarksCount()
            strongSelf.updateUserPinnedSitesCount()
        }
    }

    private func updateBookmarksCount() {
        profile.places.getRecentBookmarks(limit: UInt(minimumBookmarksCount)).uponQueue(dataQueue, block: { [weak self] result in
            guard let strongSelf = self, let bookmarks = result.successValue else { return }
            strongSelf.hasMinimumBookmarksCount = bookmarks.count >= strongSelf.minimumBookmarksCount
        })
    }

    private func updateUserPinnedSitesCount() {
        profile.history.getPinnedTopSites().uponQueue(dataQueue) { [weak self] result in
            guard let strongSelf = self, let userPinnedTopSites = result.successValue else { return }
            strongSelf.hasMinimumPinnedShortcutsCount = userPinnedTopSites.count >= strongSelf.minimumPinnedShortcutsCount
        }
    }

    private var hasRequestedInTheLastTwoWeeks: Bool {
        guard let lastRequestDate = lastRequestDate else { return false }

        let currentDate = Date()
        let numberOfDays = Calendar.current.numberOfDaysBetween(currentDate, and: lastRequestDate)

        return numberOfDays < 14
    }
}

class CumulativeDaysOfUseCounter {

    private let calendar = Calendar.current

    private struct DayOfUse: Codable {
        let date: Date
        var wasUsed: Bool = true
    }

    private enum UserDefaultsKey: String {
        case keyArrayDaysOfUse = "com.moz.arrayDaysOfUse.key"
        case keyRequiredCumulativeDaysOfUseCount = "com.moz.hasRequiredCumulativeDaysOfUseCount.key"
    }

    private let maximumNumberOfDaysToCollect = 7
    private let requiredCumulativeDaysOfUseCount = 5
    private(set) var hasRequiredCumulativeDaysOfUse: Bool {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyRequiredCumulativeDaysOfUseCount.rawValue) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyRequiredCumulativeDaysOfUseCount.rawValue) }
    }

    private var lastSevenDaysOfUse: [DayOfUse]? {
        get {
            if let data = UserDefaults.standard.data(forKey: UserDefaultsKey.keyArrayDaysOfUse.rawValue) {
                return try? PropertyListDecoder().decode([DayOfUse].self, from: data)
            } else {
                return nil
            }
        }

        set {
            if let data = try? PropertyListEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: UserDefaultsKey.keyArrayDaysOfUse.rawValue)
            }
        }
    }

    func updateCounter(currentDate: Date = Date()) {
        guard var lastSevenDaysOfUse = lastSevenDaysOfUse, let lastDayOfUse = lastSevenDaysOfUse.last else {
            let dayOfUse = DayOfUse(date: currentDate)
            lastSevenDaysOfUse = [dayOfUse]
            return
        }

        let numberOfDaysSinceLastUse = calendar.numberOfDaysBetween(currentDate, and: lastDayOfUse.date)

        // If 0 then its a consecutive day of use
        if numberOfDaysSinceLastUse <= 0 {
            let currentDayOfUse = DayOfUse(date: currentDate)
            lastSevenDaysOfUse.append(currentDayOfUse)
        }

        // CDOU: Consecutive days of use
        let numberOfCDOU = getConsecutiveDaysOfUse(daysOfUse: lastSevenDaysOfUse)
        hasRequiredCumulativeDaysOfUse = numberOfCDOU >= requiredCumulativeDaysOfUseCount ? true : false

        cleanDaysOfUseData(daysOfUse: lastSevenDaysOfUse, currentDate: currentDate)
    }

    private func getConsecutiveDaysOfUse(daysOfUse: [DayOfUse]) -> Int {
        var daysCount = 0
        var previousDay: DayOfUse?
        var maxNumberOfConsecutiveDays = 0

        for dayOfUse in daysOfUse {
            if let previousDay = previousDay {
                let countDays = calendar.numberOfDaysBetween(dayOfUse.date, and: previousDay.date)
                daysCount = countDays == 0 ? daysCount + 1 : 0
            } else {
                daysCount += 1
            }

            maxNumberOfConsecutiveDays = max(daysCount, maxNumberOfConsecutiveDays)
            previousDay = dayOfUse
        }

        return maxNumberOfConsecutiveDays
    }

    private func cleanDaysOfUseData(daysOfUse: [DayOfUse], currentDate: Date) {
        var cleanedDaysOfUse = [DayOfUse]()
        for dayOfUse in daysOfUse {
            let numberOfDays = calendar.numberOfDaysBetween(currentDate, and: dayOfUse.date)
            if numberOfDays <= maximumNumberOfDaysToCollect {
                cleanedDaysOfUse.append(dayOfUse)
            }
        }

        lastSevenDaysOfUse = cleanedDaysOfUse
    }

    func reset() {
        hasRequiredCumulativeDaysOfUse = false
        lastSevenDaysOfUse = nil
    }
}
