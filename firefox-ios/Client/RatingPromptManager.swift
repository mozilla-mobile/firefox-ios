// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import StoreKit
import Shared

/// The `RatingPromptManager` handles app store review requests and the internal logic of when
/// they can be presented to a user.
final class RatingPromptManager {
    private let prefs: Prefs
    private let logger: Logger
    private let userDefaults: UserDefaultsInterface

    struct Constants {
        static let minDaysBetweenReviewRequest = 60
        static let firstThreshold = 30
        static let secondThreshold = 90
        static let thirdThreshold = 120
    }

    enum UserDefaultsKey: String {
        case keyRatingPromptLastRequestDate = "com.moz.ratingPromptLastRequestDate.key"
        case keyRatingPromptRequestCount = "com.moz.ratingPromptRequestCount.key"
        case keyRatingPromptThreshold = "com.moz.keyRatingPromptThreshold.key"
        case keyLastCrashDateKey = "com.moz.lastCrashDateKey.key"
    }

    /// Initializes the `RatingPromptManager` using the provided profile and the user's current days of use of Firefox
    ///
    /// - Parameters:
    ///   - prefs: User's profile data
    ///   - logger: Logger protocol to override in Unit test
    init(prefs: Prefs,
         logger: Logger = DefaultLogger.shared,
         userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.prefs = prefs
        self.logger = logger
        self.userDefaults = userDefaults
    }

    /// Show the in-app rating prompt if needed
    /// - Parameter date: Request at a certain date - Useful for unit tests
    func showRatingPromptIfNeeded(at date: Date = Date()) {
        if shouldShowPrompt {
            requestRatingPrompt(at: date)
            userDefaults.set(false, forKey: PrefsKeys.ForceShowAppReviewPromptOverride)
            userDefaults.set(false, forKey: PrefsKeys.ForceShowAppReviewPromptOverride)
        }
    }

    /// Update rating prompt data
    func updateData() {
        if logger.crashedLastLaunch {
            userDefaults.set(Date(), forKey: UserDefaultsKey.keyLastCrashDateKey.rawValue)
        }
    }

    /// Go to the App Store review page of this application
    /// - Parameter urlOpener: Opens the App Store url
    static func goToAppStoreReview(with urlOpener: URLOpenerProtocol = UIApplication.shared) {
        guard let url = URL(
            string: "https://itunes.apple.com/app/id\(AppInfo.appStoreId)?action=write-review"
        ) else { return }
        urlOpener.open(url)
    }

    // MARK: UserDefaults

    private var lastRequestDate: Date? {
        get {
            return userDefaults.object(
                forKey: UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue
            ) as? Date
        }
        set {
            userDefaults.set(
                newValue,
                forKey: UserDefaultsKey.keyRatingPromptLastRequestDate.rawValue
            )
        }
    }

    private var requestCount: Int {
        get {
            userDefaults.object(
                forKey: UserDefaultsKey.keyRatingPromptRequestCount.rawValue
            ) as? Int ?? 0
        }
        set { userDefaults.set(newValue, forKey: UserDefaultsKey.keyRatingPromptRequestCount.rawValue) }
    }

    private var threshold: Int {
        get {
            userDefaults.object(
                forKey: UserDefaultsKey.keyRatingPromptThreshold.rawValue
            ) as? Int ?? 0
        }
        set { userDefaults.set(newValue, forKey: UserDefaultsKey.keyRatingPromptThreshold.rawValue) }
    }

    func reset() {
        lastRequestDate = nil
        requestCount = 0
    }

    // MARK: Private

    private var shouldShowPrompt: Bool {
        if userDefaults.bool(forKey: PrefsKeys.ForceShowAppReviewPromptOverride) {
            return true
        }

        // Required: has not crashed in the last 3 days
        guard !hasCrashedInLast3Days() else { return false }

        let launchCount = prefs.intForKey(PrefsKeys.Session.Count) ?? 0

        var daysSinceLastRequest = 0
        if let previousRequest = lastRequestDate {
            daysSinceLastRequest = Calendar.current.numberOfDaysBetween(previousRequest, and: Date())
        } else {
            daysSinceLastRequest = Constants.minDaysBetweenReviewRequest
        }

        // Required: More than `minDaysBetweenReviewRequest` since last request
        if daysSinceLastRequest < Constants.minDaysBetweenReviewRequest {
            return false
        }

        // Required: Launch count is greater than or equal to threshold
        if launchCount <= threshold {
            return false
        }

        // Change threshold for next iteration of the prompt request
        switch threshold {
        case Constants.firstThreshold:
            threshold = Constants.secondThreshold
        case Constants.secondThreshold:
            threshold = Constants.thirdThreshold
        default:
            break
        }

        return true
    }

    private func requestRatingPrompt(at date: Date) {
        lastRequestDate = date
        requestCount += 1

        logger.log("Rating prompt is being requested, this is the \(requestCount) number of time the request is made",
                   level: .info,
                   category: .setup)

        guard let scene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene else { return }

        DispatchQueue.main.async {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func hasCrashedInLast3Days() -> Bool {
        guard let lastCrashDate = userDefaults.object(
            forKey: UserDefaultsKey.keyLastCrashDateKey.rawValue
        ) as? Date else { return false }

        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        return lastCrashDate >= threeDaysAgo
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
