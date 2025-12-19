// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UserNotifications
import Combine

extension Notification.Name {
    static let searchesCounterChanged = Notification.Name("searchesCounterChanged")
    public static let searchSettingsChanged = Notification.Name("searchSettingsChanged")
}

public struct User: Codable, Equatable {
    public static var shared = User() {
        didSet {
            guard shared != oldValue else { return }
            shared.save()

            if shared.hasNewSearchSetting(compared: oldValue) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .searchSettingsChanged, object: nil)
                }
            }
        }
    }

    // MARK: Search Settings
    public var marketCode = Local.make(for: .current)
    public var adultFilter = AdultFilter.moderate
    public var autoComplete = true
    public var personalized = false
    public var aiOverviews = true

    // MARK: Privacy Settings
    public var sendAnonymousUsageData = true
    public internal(set) var cookieConsentValue: String?
    public var hasAnalyticsCookieConsent: Bool {
        guard let cookieConsentValue else {
            return false
        }
        return cookieConsentValue.contains("a")
    }

    // MARK: NTP Customization
    public var showTopSites = true
    public var topSitesRows = 4
    public var showClimateImpact = true
    public var showEcosiaNews = true

    // MARK: Install
    public var install = Date()
    public var analyticsId = UUID()
    public var versionOnInstall = "0.0.0"
    public var firstTime = true

    // MARK: Other
    public var news = Date.distantPast
    public var migrated = false
    public var referrals = Referrals.Model()
    public var seedCount: Int {
        EcosiaAuthUIStateProvider.shared.seedCount
    }
    public internal(set) var id: String?
    public var whatsNewItemsVersionsShown = Set<String>()
    public internal(set) var analyticsUserState = AnalyticsStateContext()

    public var searchCount = 0 {
        didSet {
            guard oldValue != searchCount else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .searchesCounterChanged, object: nil)
            }
        }
    }

    var state = [String: String]()

    private enum CodingKeys: String, CodingKey {
        case
        install,
        versionOnInstall,
        news,
        analyticsId,
        marketCode,
        adultFilter,
        autoComplete,
        firstTime,
        personalized,
        aiOverviews,
        sendAnonymousUsageData,
        topSitesRows,
        showClimateImpact,
        showEcosiaNews,
        migrated,
        referrals,
        id,
        state,
        cookieConsentValue,
        whatsNewItemsVersionsShown,
        analyticsUserState
        // Reusing previous decoding keys
        case searchCount = "treeCount"
        case showTopSites = "topSites"
    }

    public init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        install = (try? root.decode(Date.self, forKey: .install)) ?? .init()
        versionOnInstall = (try? root.decode(String.self, forKey: .versionOnInstall)) ?? "0.0.0"
        news = (try? root.decode(Date.self, forKey: .news)) ?? .distantPast
        analyticsId = (try? root.decode(UUID.self, forKey: .analyticsId)) ?? .init()
        marketCode = (try? root.decode(Local.self, forKey: .marketCode)) ?? Local.make(for: .current)
        adultFilter = (try? root.decode(AdultFilter.self, forKey: .adultFilter)) ?? .moderate
        autoComplete = (try? root.decode(Bool.self, forKey: .autoComplete)) ?? true
        firstTime = (try? root.decode(Bool.self, forKey: .firstTime)) ?? true
        personalized = (try? root.decode(Bool.self, forKey: .personalized)) ?? false
        aiOverviews = (try? root.decode(Bool.self, forKey: .aiOverviews)) ?? true
        sendAnonymousUsageData = (try? root.decode(Bool.self, forKey: .sendAnonymousUsageData)) ?? true
        topSitesRows = (try? root.decode(Int.self, forKey: .topSitesRows)) ?? 4
        showTopSites = (try? root.decode(Bool.self, forKey: .showTopSites)) ?? true
        showClimateImpact = (try? root.decode(Bool.self, forKey: .showClimateImpact)) ?? true
        showEcosiaNews = (try? root.decode(Bool.self, forKey: .showEcosiaNews)) ?? true
        migrated = (try? root.decode(Bool.self, forKey: .migrated)) ?? false
        referrals = (try? root.decode(Referrals.Model.self, forKey: .referrals)) ?? .init()
        id = try? root.decode(String.self, forKey: .id)
        searchCount = (try? root.decode(Int.self, forKey: .searchCount)) ?? 0
        state = (try? root.decode([String: String].self, forKey: .state)) ?? [:]
        cookieConsentValue = try? root.decode(String.self, forKey: .cookieConsentValue)
        whatsNewItemsVersionsShown = (try? root.decode(Set<String>.self, forKey: .whatsNewItemsVersionsShown)) ?? []
        analyticsUserState = (try? root.decode(AnalyticsStateContext.self, forKey: .analyticsUserState)) ?? .init()
    }

    init() {
        if let stored = self.stored {
            id = stored.id
            adultFilter = stored.adultFilter
            marketCode = stored.marketCode
            searchCount = stored.searchCount
            autoComplete = stored.autoComplete
            firstTime = stored.firstTime
            analyticsId = stored.analyticsId
            personalized = stored.personalized
            aiOverviews = stored.aiOverviews
            sendAnonymousUsageData = stored.sendAnonymousUsageData
            migrated = stored.migrated
            state = stored.state
            news = stored.news
            topSitesRows = stored.topSitesRows
            showTopSites = stored.showTopSites
            showClimateImpact = stored.showClimateImpact
            showEcosiaNews = stored.showEcosiaNews
            referrals = stored.referrals
            install = stored.install
            versionOnInstall = stored.versionOnInstall
            cookieConsentValue = stored.cookieConsentValue
            whatsNewItemsVersionsShown = stored.whatsNewItemsVersionsShown
            analyticsUserState = stored.analyticsUserState
        } else {
            save()
        }
    }

    private var stored: User? {
        try? JSONDecoder().decode(User.self, from: .init(contentsOf: FileManager.user))
    }

    static let queue = DispatchQueue(label: "", qos: .utility)
    private func save() {
        let user = self
        User.queue.async {
            try? JSONEncoder().encode(user).write(to: FileManager.user, options: .atomic)
        }
    }
}

// MARK: Helper methods
extension User {

    public var showsReferralSpotlight: Bool {
        guard install < Calendar.current.date(byAdding: .day, value: -3, to: .init())! else { return false }
        return state[Key.referralSpotlight.rawValue].map(Bool.init) != false
    }

    public var showsInactiveTabsTooltip: Bool {
        state[Key.inactiveTabsTooltip.rawValue].map(Bool.init) != false
    }

    public var showsBookmarksImportExportTooltip: Bool {
        state[Key.bookmarksImportExportTooltipShown.rawValue].map(Bool.init) != false
    }

    public var shouldShowImpactIntro: Bool {
        state[Key.impactIntro.rawValue].map(Bool.init) != false
    }

    public mutating func hideImpactIntro() {
        state[Key.impactIntro.rawValue] = "\(false)"
    }

    public mutating func showImpactIntro() {
        state[Key.impactIntro.rawValue] = "\(true)"
    }

    public mutating func hideReferralSpotlight() {
        state[Key.referralSpotlight.rawValue] = "\(false)"
    }

    public mutating func showInactiveTabsTooltip() {
        state[Key.inactiveTabsTooltip.rawValue] = "\(true)"
    }

    public mutating func hideInactiveTabsTooltip() {
        state[Key.inactiveTabsTooltip.rawValue] = "\(false)"
    }

    public mutating func hideBookmarksImportExportTooltip() {
        state[Key.bookmarksImportExportTooltipShown.rawValue] = "\(false)"
    }

    public var shouldShowDefaultBrowserSettingNudgeCard: Bool {
        state[Key.isDefaultBrowserSettingNudgeCardShown.rawValue].map(Bool.init) != true
    }

    public mutating func showDefaultBrowserSettingNudgeCard() {
        state[Key.isDefaultBrowserSettingNudgeCardShown.rawValue] = "\(false)"
    }

    public mutating func hideDefaultBrowserSettingNudgeCard() {
        state[Key.isDefaultBrowserSettingNudgeCardShown.rawValue] = "\(true)"
    }

    public var shouldShowAccountImpactNudgeCard: Bool {
        state[Key.isAccountImpactNudgeCardDismissed.rawValue].map(Bool.init) != true
    }

    public mutating func showAccountImpactNudgeCard() {
        state[Key.isAccountImpactNudgeCardDismissed.rawValue] = "\(false)"
    }

    public mutating func hideAccountImpactNudgeCard() {
        state[Key.isAccountImpactNudgeCardDismissed.rawValue] = "\(true)"
    }

    enum Key: String {
        case
        referralSpotlight,
        impactIntro = "counterIntro", // Reusing previous key
        inactiveTabsTooltip,
        bookmarksImportExportTooltipShown,
        isNewUserSinceBookmarksImportExportHasBeenShipped,
        isDefaultBrowserSettingNudgeCardShown,
        isAccountImpactNudgeCardDismissed
    }
}

// MARK: Search Setting Helper
extension User {
    private struct SearchSetting: Equatable {
        let marketCode: Local
        let adultFilter: AdultFilter
        let autoComplete: Bool
        let personalized: Bool
        let aiOverviews: Bool
    }

    private var searchSetting: SearchSetting {
        .init(marketCode: marketCode,
              adultFilter: adultFilter,
              autoComplete: autoComplete,
              personalized: personalized,
              aiOverviews: aiOverviews)
    }

    func hasNewSearchSetting(compared to: User) -> Bool {
        searchSetting != to.searchSetting
    }
}

// MARK: User state context
extension User {

    /// Mimics the high level push notification states
    public enum PushNotificationState: String, Codable {
        case enabled
        case disabled
        case notDetermined = "not_determined"
    }

    /// The values to pass into the Analytics User State Dedicated context
    public struct AnalyticsStateContext: Codable, Equatable {
        var pushNotificationState: PushNotificationState = .notDetermined

        enum CodingKeys: String, CodingKey {
            case pushNotificationState = "push_notification_state"
        }
    }

    /// Updates the Analytics' User State given the current App's User Notification's status
    public mutating func updatePushNotificationUserStateWithAnalytics(from status: UNAuthorizationStatus) {
        analyticsUserState.pushNotificationState = switch status {
        case .authorized, .ephemeral, .provisional: .enabled
        case .denied: .disabled
        default: .notDetermined
        }
    }
}
