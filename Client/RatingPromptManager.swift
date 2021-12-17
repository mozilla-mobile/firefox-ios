// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import StoreKit
import Shared
import Storage

// The `RatingPromptManager` handles app store review requests and the internal logic of when they can be presented to a user.
class RatingPromptManager {

    private let profile: Profile
    private let daysOfUseCounter: CumulativeDaysOfUseCounter

    private var hasMinimumBookmarksCount = false
    private let minimumBookmarksCount = 5

    private var hasMinimumPinnedShortcutsCount = false
    private let minimumPinnedShortcutsCount = 2

    private let dataQueue = DispatchQueue(label: "com.moz.ratingPromptManager.queue")

    enum UserDefaultsKey: String {
        case keyIsBrowserDefault = "com.moz.isBrowserDefault.key"
        case keyRatingPromptLastRequestDate = "com.moz.ratingPromptLastRequestDate.key"
        case keyRatingPromptRequestCount = "com.moz.ratingPromptRequestCount.key"
    }

    /// Initializes the `RatingPromptManager` using the provided profile and the user's current days of use of Firefox
    ///
    /// - Parameters:
    ///   - profile: User's profile data
    ///   - daysOfUseCounter: Counter for the cumulative days of use of the application by the user
    init(profile: Profile,
         daysOfUseCounter: CumulativeDaysOfUseCounter) {
        self.profile = profile
        self.daysOfUseCounter = daysOfUseCounter
    }

    /// Show the in-app rating prompt if needed
    /// - Parameter date: Request at a certain date - Useful for unit tests
    func showRatingPromptIfNeeded(at date: Date = Date()) {
        if shouldShowPrompt {
            requestRatingPrompt(at: date)
        }
    }

    /// Updates bookmark and pinned site data asynchronously.
    /// - Parameter dataLoadingCompletion: Complete when the loading of data from the profile is done - Used in unit tests
    func updateData(dataLoadingCompletion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        updateBookmarksCount(group: group)
        updateUserPinnedSitesCount(group: group)

        group.notify(queue: dataQueue) {
            dataLoadingCompletion?()
        }
    }

    /// Go to the App Store review page of this application
    /// - Parameter urlOpener: Opens the App Store url
    static func goToAppStoreReview(with urlOpener: URLOpenerProtocol = UIApplication.shared) {
        guard let url = URL(string: "https://itunes.apple.com/app/id\(AppInfo.appStoreId)?action=write-review") else { return }
        urlOpener.open(url)
    }

    // MARK: UserDefaults

    static var isBrowserDefault: Bool {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyIsBrowserDefault.rawValue) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyIsBrowserDefault.rawValue) }
    }

    private var lastRequestDate: Date? {
        get { return UserDefaults.standard.object(forKey: UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue) }
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

        // Required: has not crashed in the last session
        guard !Sentry.shared.crashedLastLaunch else { return false }

        // One of the following
        let isBrowserDefault = RatingPromptManager.isBrowserDefault
        let hasSyncAccount = profile.hasSyncableAccount()
        let engineIsGoogle = profile.searchEngines.defaultEngine.shortName == "Google"
        let hasTPStrict = profile.prefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap({BlockingStrength(rawValue: $0)}) == .strict
        guard isBrowserDefault
                || hasSyncAccount
                || hasMinimumBookmarksCount
                || hasMinimumPinnedShortcutsCount
                || !engineIsGoogle
                || hasTPStrict
        else { return false }

        // Ensure we ask again only if 2 weeks has passed
        guard !hasRequestedInTheLastTwoWeeks else { return false }

        // As per Apple's framework, an app can only present the prompt three times per period of 365 days.
        // Because of this, Firefox will currently limit its request to show the ratings prompt to one time, given
        // that the triggers are fulfilled. As such, requirements and attempts to further show the ratings prompt
        // will be implemented later in the future.
        guard requestCount < 1 else { return false }

        return true
    }

    private func requestRatingPrompt(at date: Date) {
        lastRequestDate = date
        requestCount += 1

        SKStoreReviewController.requestReview()
    }

    private func updateBookmarksCount(group: DispatchGroup) {
        group.enter()
        profile.places.getRecentBookmarks(limit: UInt(minimumBookmarksCount)).uponQueue(dataQueue, block: { [weak self] result in
            guard let strongSelf = self, let bookmarks = result.successValue else { return }
            strongSelf.hasMinimumBookmarksCount = bookmarks.count >= strongSelf.minimumBookmarksCount
            group.leave()
        })
    }

    private func updateUserPinnedSitesCount(group: DispatchGroup) {
        group.enter()
        profile.history.getPinnedTopSites().uponQueue(dataQueue) { [weak self] result in
            guard let strongSelf = self, let userPinnedTopSites = result.successValue else { return }
            strongSelf.hasMinimumPinnedShortcutsCount = userPinnedTopSites.count >= strongSelf.minimumPinnedShortcutsCount
            group.leave()
        }
    }

    private var hasRequestedInTheLastTwoWeeks: Bool {
        guard let lastRequestDate = lastRequestDate else { return false }

        let currentDate = Date()
        let numberOfDays = Calendar.current.numberOfDaysBetween(lastRequestDate, and: currentDate)

        return numberOfDays <= 14
    }
}

// MARK: URLOpenerProtocol
extension UIApplication: URLOpenerProtocol {
    func open(_ url: URL) {
        open(url, options: [:], completionHandler: nil)
    }
}

protocol URLOpenerProtocol {
    func open(_ url: URL)
}
