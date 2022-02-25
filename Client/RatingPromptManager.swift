// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import StoreKit
import Shared
import Storage

// The `RatingPromptManager` handles app store review requests and the internal logic of when they can be presented to a user.
final class RatingPromptManager {

    private let profile: Profile
    private let daysOfUseCounter: CumulativeDaysOfUseCounter

    private var hasMinimumMobileBookmarksCount = false
    private let minimumMobileBookmarksCount = 5
    private let sentry: SentryProtocol?

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
    ///   - sentry: Sentry protocol to override in Unit test
    init(profile: Profile,
         daysOfUseCounter: CumulativeDaysOfUseCounter = CumulativeDaysOfUseCounter(),
         sentry: SentryProtocol = Sentry.shared) {
        self.profile = profile
        self.daysOfUseCounter = daysOfUseCounter
        self.sentry = sentry
    }

    /// Show the in-app rating prompt if needed
    /// - Parameter date: Request at a certain date - Useful for unit tests
    func showRatingPromptIfNeeded(at date: Date = Date()) {
        if shouldShowPrompt {
            requestRatingPrompt(at: date)
        }
    }

    /// Update rating prompt data. Bookmarks and pinned sites data is loaded asynchronously.
    /// - Parameter dataLoadingCompletion: Complete when the loading of data from the profile is done - Used in unit tests
    func updateData(dataLoadingCompletion: (() -> Void)? = nil) {
        daysOfUseCounter.updateCounter()

        let group = DispatchGroup()
        updateBookmarksCount(group: group)

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
        guard let sentry = sentry, !sentry.crashedLastLaunch else { return false }

        // One of the following
        let isBrowserDefault = RatingPromptManager.isBrowserDefault
        let hasTPStrict = profile.prefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap({BlockingStrength(rawValue: $0)}) == .strict
        guard isBrowserDefault
                || hasMinimumMobileBookmarksCount
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
        profile.places.getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: false).uponQueue(.main) { [weak self] result in
            guard let strongSelf = self,
                  let mobileFolder = result.successValue as? BookmarkFolderData,
                  let children = mobileFolder.children
            else {
                group.leave()
                return
            }

            let bookmarksCounts = children.filter { $0.type == .bookmark }.count
            strongSelf.hasMinimumMobileBookmarksCount = bookmarksCounts >= strongSelf.minimumMobileBookmarksCount
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
