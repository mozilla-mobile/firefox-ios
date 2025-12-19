// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
internal import SnowplowTracker

open class Analytics {
    private static let abTestSchema = "iglu:org.ecosia/abtest_context/jsonschema/1-0-1"
    private static let consentSchema = "iglu:org.ecosia/eccc_context/jsonschema/1-0-2"
    private static let feedbackSchema = "iglu:org.ecosia/ios_feedback_event/jsonschema/1-0-0"
    static let impactBalanceSchema = "iglu:org.ecosia/impact_balance/jsonschema/1-0-0"
    private static let abTestRoot = "ab_tests"
    private static let namespace = "ios_sp"
    static let installSchema = "iglu:org.ecosia/ios_install_event/jsonschema/1-0-0"
    static let userSchema = "iglu:org.ecosia/app_user_state_context/jsonschema/1-0-0"
    static let inappSearchSchema = "iglu:org.ecosia/inapp_search_event/jsonschema/1-0-1"
    private static let shouldUseMicroInstanceKey = "shouldUseMicroInstance"
    public static var shouldUseMicroInstance: Bool {
        get {
            UserDefaults.standard.bool(forKey: shouldUseMicroInstanceKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: shouldUseMicroInstanceKey)
            Analytics.updateTrackerController()
        }
    }

    public static var shared = Analytics()
    private var tracker: TrackerController
    private let notificationCenter: AnalyticsUserNotificationCenterProtocol

    internal init(notificationCenter: AnalyticsUserNotificationCenterProtocol = AnalyticsUserNotificationCenterWrapper()) {
        tracker = Self.makeTracker()
        tracker.installAutotracking = true
        tracker.screenViewAutotracking = false
        tracker.lifecycleAutotracking = false
        tracker.screenEngagementAutotracking = false
        tracker.exceptionAutotracking = false
        tracker.diagnosticAutotracking = false
        self.notificationCenter = notificationCenter
    }

    internal func track(_ event: SnowplowTracker.Event) {
        guard User.shared.sendAnonymousUsageData else { return }
        if let structuredEvent = event as? Structured {
            appendContextIfNeeded(to: structuredEvent)
        }
#if !TESTING
        _ = tracker.track(event)
#endif
    }

    private static func updateTrackerController() {
        Analytics.shared.tracker = makeTracker()
    }

    private static func getTestContext(from toggle: Unleash.Toggle.Name) -> SelfDescribingJson? {
        let variant = Unleash.getVariant(toggle).name
        guard variant != "disabled" else { return nil }

        let variantContext: [String: String] = [toggle.rawValue: variant]
        let abTestContext: [String: AnyHashable] = [abTestRoot: variantContext]
        return SelfDescribingJson(schema: abTestSchema, andDictionary: abTestContext)
    }

    public func reset() {
        User.shared.analyticsId = .init()
        tracker = Self.makeTracker()
    }

    // MARK: App events
    public func install() {
        track(SelfDescribing(schema: Self.installSchema,
                             payload: ["app_v": Bundle.version as NSObject]))
    }

    public func activity(_ action: Action.Activity) {
        let event = Structured(category: Category.activity.rawValue,
                               action: action.rawValue)
            .label(Analytics.Label.Navigation.inapp.rawValue)

        appendActivityContextIfNeeded(action, event) { [weak self] in
            self?.track(event)
        }
    }

    // MARK: Bookmarks
    public func bookmarksPerformImportExport(_ property: Property.Bookmarks) {
        let event = Structured(category: Category.bookmarks.rawValue,
                               action: Action.click.rawValue)
            .label(Label.Bookmarks.importFunctionality.rawValue)
            .property(property.rawValue)
        track(event)
    }

    public func bookmarksEmptyLearnMoreClicked() {
        let event = Structured(category: Category.bookmarks.rawValue,
                               action: Action.click.rawValue)
            .label(Label.Bookmarks.learnMore.rawValue)
            .property(Property.Bookmarks.emptyState.rawValue)
        track(event)
    }

    public func bookmarksImportEnded(_ property: Property.Bookmarks) {
        let event = Structured(category: Category.bookmarks.rawValue,
                               action: Action.Bookmarks.import.rawValue)
            .label(Label.Bookmarks.import.rawValue)
            .property(property.rawValue)
        track(event)
    }

    // MARK: Braze IAM
    public func brazeIAM(action: Action.BrazeIAM, messageOrButtonId: String?) {
        track(Structured(category: Category.brazeIAM.rawValue,
                         action: action.rawValue)
            .property(messageOrButtonId))
    }

    // MARK: Default Browser
    public func appOpenAsDefaultBrowser() {
        let event = Structured(category: Category.external.rawValue,
                               action: Action.receive.rawValue)
            .label(Label.DefaultBrowser.deeplink.rawValue)

        track(event)
    }

    public func defaultBrowser(_ action: Action.Promo) {
        track(Structured(category: Category.browser.rawValue,
                         action: action.rawValue)
            .label(Label.DefaultBrowser.promo.rawValue)
            .property(Property.home.rawValue))
    }

    public func defaultBrowserSettingsShowsDetailViewVia(_ label: Label.DefaultBrowser) {
        track(Structured(category: Category.browser.rawValue,
                         action: Action.open.rawValue)
            .label(label.rawValue))
    }

    public func defaultBrowserSettingsViaNudgeCardDismiss() {
        track(Structured(category: Category.browser.rawValue,
                         action: Action.dismiss.rawValue)
            .label(Label.DefaultBrowser.settingsNudgeCard.rawValue))
    }

    public func defaultBrowserSettingsOpenNativeSettingsVia(_ label: Label.DefaultBrowser) {
        track(Structured(category: Category.browser.rawValue,
                         action: Action.click.rawValue)
            .label(label.rawValue)
            .property(Property.nativeSettings.rawValue))
    }

    public func defaultBrowserSettingsDismissDetailViewVia(_ label: Label.DefaultBrowser) {
        track(Structured(category: Category.browser.rawValue,
                         action: Action.dismiss.rawValue)
            .label(label.rawValue)
            .property(Property.detail.rawValue))
    }

    // MARK: Menu
    public func menuClick(_ item: Analytics.Label.Menu) {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.click.rawValue)
            .label(item.rawValue)
        track(event)
    }

    public func menuShare(_ content: Property.ShareContent) {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.click.rawValue)
            .label(Label.Menu.share.rawValue)
            .property(content.rawValue)
        track(event)
    }

    public func menuStatus(changed item: Analytics.Label.MenuStatus, to: Bool) {
        let event = Structured(category: Category.menuStatus.rawValue,
                               action: Action.click.rawValue)
            .label(item.rawValue)
            .value(.init(value: to))
        track(event)
    }

    // MARK: Migration
    public func migration(_ success: Bool) {
        track(Structured(category: Category.migration.rawValue,
                         action: success ? Action.success.rawValue : Action.error.rawValue))
    }

    public func migrationError(in migration: Label.Migration, message: String) {
        track(Structured(category: Category.migration.rawValue,
                         action: Action.error.rawValue)
            .label(migration.rawValue)
            .property(message))
    }

    // MARK: Navigation
    public func navigation(_ action: Action, label: Label.Navigation) {
        track(Structured(category: Category.navigation.rawValue,
                         action: action.rawValue)
            .label(label.rawValue))
    }

    public func navigationOpenNews(_ id: String) {
        track(Structured(category: Category.navigation.rawValue,
                         action: Action.open.rawValue)
            .label(Label.Navigation.news.rawValue)
            .property(id))
    }

    public func navigationChangeMarket(_ new: String) {
        track(Structured(category: Category.navigation.rawValue,
                         action: Action.change.rawValue)
            .label(Label.Navigation.market.rawValue)
            .property(new))
    }

    // MARK: NTP
    public func ntpCustomisation(_ action: Action.NTPCustomization, label: Label.NTP) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(label.rawValue))
    }

    public func ntpTopSite(_ action: Action.TopSite, property: Property.TopSite, position: NSNumber? = nil) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(Label.NTP.topSites.rawValue)
            .property(property.rawValue)
            .value(position))
    }

    public func ntpLibraryItem(_ action: Action, property: Property.Library) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(Label.NTP.quickActions.rawValue)
            .property(property.rawValue))
    }

    public func ntpSeedCounterExperiment(_ action: Action.SeedCounter, value: NSNumber) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(Label.NTP.climateCounter.rawValue)
            .value(value)
        )
    }

    // MARK: Onboarding
    public func introDisplaying(page: Property.OnboardingPage?) {
        guard let page else {
            return
        }
        let event = Structured(category: Category.intro.rawValue,
                               action: Action.display.rawValue)
            .property(page.rawValue)
        track(event)
    }

    public func introClick(_ label: Label.Onboarding, page: Property.OnboardingPage?) {
        guard let page else {
            return
        }
        let event = Structured(category: Category.intro.rawValue,
                               action: Action.click.rawValue)
            .label(label.rawValue)
            .property(page.rawValue)
        track(event)
    }

    // MARK: Push Notifications Consent
    func apnConsent(_ action: Action.APNConsent) {
        let event = Structured(category: Category.pushNotificationConsent.rawValue,
                               action: action.rawValue)
            .property(Property.APNConsent.onLaunchPrompt.rawValue)
        track(event)
    }

    // MARK: Referrals
    public func referral(action: Action.Referral, label: Label.Referral? = nil) {
        track(Structured(category: Category.invitations.rawValue,
                         action: action.rawValue)
            .label(label?.rawValue))
    }

    // MARK: In-App Search
    public func inappSearch(url: URL) {
        guard NativeSRPVAnalyticsExperiment.isEnabled,
              let query = url.getEcosiaSearchQuery() else {
            return
        }
        let payload: [String: Any?] = [
            "query": query,
            "page_num": url.getEcosiaSearchPage(),
            "plt_name": "ios",
            "plt_v": Bundle.version as NSObject,
            "search_type": url.getEcosiaSearchVerticalPath()
        ]
        track(SelfDescribing(schema: Self.inappSearchSchema,
                             payload: payload.compactMapValues({ $0 })))
    }

    // MARK: Settings
    public func searchbarChanged(to position: String) {
        track(Structured(category: Category.settings.rawValue,
                         action: Action.change.rawValue)
            .label(Label.Settings.toolbar.rawValue)
            .property(position))
    }

    public func toggleAISearchOverviewsSetting(enabled: Bool) {
        track(Structured(category: Category.settings.rawValue,
                         action: Action.change.rawValue)
            .label(Label.Settings.aiOverviews.rawValue)
            .property(enabled ? Property.enable.rawValue : Property.disable.rawValue))
    }

    public func sendAnonymousUsageDataSetting(enabled: Bool) {
        // This is the only place where the tracker should be directly
        // used since we want to send this just as the user opts out
        _ = tracker.track(Structured(category: Category.settings.rawValue,
                                     action: Action.change.rawValue)
            .label(Label.Settings.analytics.rawValue)
            .property(enabled ? Property.enable.rawValue : Property.disable.rawValue))
    }

    public func clearsDataFromSection(_ section: Analytics.Property.SettingsPrivateDataSection) {
        track(Structured(category: Category.settings.rawValue,
                         action: Action.click.rawValue)
            .label(Analytics.Label.Settings.clear.rawValue)
            .property(section.rawValue))
    }

    // MARK: Feedback

    public func sendFeedback(_ feedback: String, withType feedbackType: FeedbackType) {
        let deviceType = UIDevice.current.model
        let operatingSystem = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        let idiom = UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        let browserVersion = "Ecosia \(idiom) \(Bundle.version)"

        let payload: [String: Any] = [
            "feedback_type": feedbackType.analyticsIdentfier,
            "device_type": deviceType,
            "os": operatingSystem,
            "browser_version": browserVersion,
            "feedback_text": feedback
        ]

        track(SelfDescribing(schema: Self.feedbackSchema,
                             payload: payload))
    }

    // MARK: AI Search MVP

    public func aiSearchNTPButtonTapped() {
        track(Structured(category: Category.ntp.rawValue,
                         action: Action.click.rawValue)
            .label(Analytics.Label.AISearch.cta.rawValue)
            .property(Analytics.Property.header.rawValue))
    }

    public func aiSearchAutocompleteForQuery(_ text: String) {
        track(Structured(category: Category.autocomplete.rawValue,
                         action: Action.click.rawValue)
            .label(Analytics.Label.AISearch.cta.rawValue)
            .property(text))
	}

    // MARK: Account Authentication

    public func accountHeaderClicked() {
        let event = Structured(category: Category.account.rawValue,
                               action: Action.click.rawValue)
            .label(Label.signIn.rawValue)
            .property(Property.header.rawValue)
        track(event)
    }

    public func accountSignInCancelled() {
        let event = Structured(category: Category.account.rawValue,
                               action: Action.click.rawValue)
            .label(Label.signIn.rawValue)
            .property(Property.cancel.rawValue)
        track(event)
    }

    public func accountImpactSignUpClicked() {
        let event = Structured(category: Category.account.rawValue,
                               action: Action.click.rawValue)
            .label(Label.signUp.rawValue)
            .property(Property.menu.rawValue)
        track(event)
    }

    public func accountImpactCloseClicked() {
        let event = Structured(category: Category.account.rawValue,
                               action: Action.click.rawValue)
            .label(Label.close.rawValue)
            .property(Property.menu.rawValue)
        track(event)
    }

    public func accountImpactCardCtaClicked() {
        let event = Structured(category: Category.account.rawValue,
                               action: Action.click.rawValue)
            .label(Label.accountNudgeCard.rawValue)
            .property(Property.menu.rawValue)
        track(event)
    }

    public func accountImpactCardDismissClicked() {
        let event = Structured(category: Category.account.rawValue,
                               action: Action.dismiss.rawValue)
            .label(Label.accountNudgeCard.rawValue)
            .property(Property.menu.rawValue)
        track(event)
    }

    public func accountProfileClicked() {
        let event = Structured(category: Category.account.rawValue,
                               action: Action.click.rawValue)
            .label(Label.profile.rawValue)
            .property(Property.menu.rawValue)
        track(event)
    }

    public func accountSignOutClicked() {
        let event = Structured(category: Category.account.rawValue,
                               action: Action.click.rawValue)
            .label(Label.profile.rawValue)
            .property(Property.signOut.rawValue)
        track(event)
    }

    public func accountProfileViewed() {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.view.rawValue)
            .label(Label.profile.rawValue)
            .property(Property.account.rawValue)
        track(event)
    }

    public func accountProfileDismissed() {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.dismiss.rawValue)
            .label(Label.profile.rawValue)
            .property(Property.account.rawValue)
        track(event)
    }
}

extension Analytics {

    /// Appends common context to all structured events
    func appendContextIfNeeded(to event: Structured) {
        addUserSeedCountContext(to: event)
    }

    /// Appends activity-specific context for launch/resume events
    func appendActivityContextIfNeeded(_ action: Analytics.Action.Activity, _ event: Structured, completion: @escaping () -> Void) {
        switch action {
        case .resume, .launch:
            addABTestContexts(to: event, toggles: [.brazeIntegration])
            addCookieConsentContext(to: event)
            addUserStateContext(to: event, completion: completion)
        }
    }

    private func addABTestContexts(to event: Structured, toggles: [Unleash.Toggle.Name]) {
        toggles.forEach { toggle in
            if let context = Self.getTestContext(from: toggle) {
                event.entities.append(context)
            }
        }
    }

    private func addCookieConsentContext(to event: Structured) {
        if let consentValue = User.shared.cookieConsentValue {
            let consentContext = SelfDescribingJson(schema: Self.consentSchema,
                                                    andDictionary: ["cookie_consent": consentValue])
            event.entities.append(consentContext)
        }
    }

    private func addUserStateContext(to event: Structured, completion: @escaping () -> Void) {
        notificationCenter.getNotificationSettingsProtocol { settings in
            User.shared.updatePushNotificationUserStateWithAnalytics(from: settings.authorizationStatus)
            let userContext = SelfDescribingJson(schema: Self.userSchema,
                                                 andDictionary: User.shared.analyticsUserState.dictionary)
            event.entities.append(userContext)
            completion()
        }
    }

    private func addUserSeedCountContext(to event: Structured) {
        let consentContext = SelfDescribingJson(schema: Self.impactBalanceSchema,
                                                andDictionary: ["amount": User.shared.seedCount])
        event.entities.append(consentContext)
    }
}

extension Analytics {

    /// Creates and configures a new instance of `TrackerController` using Snowplow.
    ///
    /// - Returns: A configured `TrackerController` instance, which in non-release builds can either point to mini or micro Snowplow instance.
    private static func makeTracker() -> TrackerController {
        return Snowplow.createTracker(namespace: namespace,
                                      network: makeNetworkConfig(),
                                      configurations: [
                                        Self.trackerConfiguration,
                                        Self.subjectConfiguration,
                                        Self.appInstallTrackingPluginConfiguration,
                                        Self.appResumeDailyTrackingPluginConfiguration])
    }

    /// Factory that builds the `NetworkConfiguration` for the Snowplow tracker, optionally
    /// including authentication headers if using a micro instance.
    ///
    /// - Returns: A configured `NetworkConfiguration` object.
    /// - Parameters:
    ///   - urlProvider: The urlProvider in use. Useful for testing purposes.
    static func makeNetworkConfig(urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> NetworkConfiguration {
        let endpoint = shouldUseMicroInstance ? urlProvider.snowplowMicro : urlProvider.snowplow
        var networkConfig = NetworkConfiguration(endpoint: endpoint!)

        if shouldUseMicroInstance,
           let auth = EcosiaEnvironment.current.cloudFlareAuth {
            networkConfig = networkConfig
                .requestHeaders([
                    CloudflareKeyProvider.clientId: auth.id,
                    CloudflareKeyProvider.clientSecret: auth.secret
                ])
        }

        return networkConfig
    }
}
