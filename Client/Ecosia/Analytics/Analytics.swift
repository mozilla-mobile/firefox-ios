// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SnowplowTracker
import Core

open class Analytics {
    static let installSchema = "iglu:org.ecosia/ios_install_event/jsonschema/1-0-0"
    private static let abTestSchema = "iglu:org.ecosia/abtest_context/jsonschema/1-0-1"
    private static let consentSchema = "iglu:org.ecosia/eccc_context/jsonschema/1-0-2"
    static let userSchema = "iglu:org.ecosia/app_user_state_context/jsonschema/1-0-3"
    private static let abTestRoot = "ab_tests"
    private static let namespace = "ios_sp"

    private static var tracker: TrackerController {

        return Snowplow.createTracker(namespace: namespace,
                                      network: .init(endpoint: Environment.current.urlProvider.snowplow),
                                      configurations: [Self.trackerConfiguration,
                                                       Self.subjectConfiguration,
                                                       Self.appInstallTrackingPluginConfiguration,
                                                       Self.appResumeDailyTrackingPluginConfiguration])
    }

    static var shared = Analytics()
    private var tracker: TrackerController
    private let notificationCenter: AnalyticsUserNotificationCenterProtocol

    internal init(notificationCenter: AnalyticsUserNotificationCenterProtocol = AnalyticsUserNotificationCenterWrapper()) {
        tracker = Self.tracker
        tracker.installAutotracking = true
        tracker.screenViewAutotracking = false
        tracker.lifecycleAutotracking = false
        tracker.screenEngagementAutotracking = false
        tracker.exceptionAutotracking = false
        tracker.diagnosticAutotracking = false
        self.notificationCenter = notificationCenter
    }

    private func track(_ event: Event) {
        guard User.shared.sendAnonymousUsageData else { return }
        _ = tracker.track(event)
    }

    private static func getTestContext(from toggle: Unleash.Toggle.Name) -> SelfDescribingJson? {
        let variant = Unleash.getVariant(toggle).name
        guard variant != "disabled" else { return nil }

        let variantContext: [String: String] = [toggle.rawValue: variant]
        let abTestContext: [String: AnyHashable] = [abTestRoot: variantContext]
        return SelfDescribingJson(schema: abTestSchema, andDictionary: abTestContext)
    }

    func reset() {
        User.shared.analyticsId = .init()
        tracker = Self.tracker
    }

    // MARK: App events
    func install() {
        track(SelfDescribing(schema: Self.installSchema,
                             payload: ["app_v": Bundle.version as NSObject]))
    }

    func activity(_ action: Action.Activity) {
        let event = Structured(category: Category.activity.rawValue,
                               action: action.rawValue)
            .label(Analytics.Label.Navigation.inapp.rawValue)

        appendTestContextIfNeeded(action, event) { [weak self] in
            self?.track(event)
        }
    }

    // MARK: Bookmarks
    func bookmarksPerformImportExport(_ property: Property.Bookmarks) {
        let event = Structured(category: Category.bookmarks.rawValue,
                               action: Action.click.rawValue)
            .label(Label.Bookmarks.importFunctionality.rawValue)
            .property(property.rawValue)
        track(event)
    }

    func bookmarksEmptyLearnMoreClicked() {
        let event = Structured(category: Category.bookmarks.rawValue,
                               action: Action.click.rawValue)
            .label(Label.Bookmarks.learnMore.rawValue)
            .property(Property.Bookmarks.emptyState.rawValue)
        track(event)
    }

    func bookmarksImportEnded(_ property: Property.Bookmarks) {
        let event = Structured(category: Category.bookmarks.rawValue,
                               action: Action.Bookmarks.import.rawValue)
            .label(Label.Bookmarks.import.rawValue)
            .property(property.rawValue)
        track(event)
    }

    // MARK: Braze IAM
    func brazeIAM(action: Action.BrazeIAM, messageOrButtonId: String?) {
        track(Structured(category: Category.brazeIAM.rawValue,
                         action: action.rawValue)
            .property(messageOrButtonId))
    }

    // MARK: Default Browser
    func appOpenAsDefaultBrowser() {
        let event = Structured(category: Category.external.rawValue,
                               action: Action.receive.rawValue)
            .label(Label.DefaultBrowser.deeplink.rawValue)

        track(event)
    }

    func defaultBrowser(_ action: Action.Promo) {
        let event = Structured(category: Category.browser.rawValue,
                               action: action.rawValue)
            .label(Label.DefaultBrowser.promo.rawValue)
            .property(Property.home.rawValue)

        track(event)
    }

    func defaultBrowserSettings() {
        track(Structured(category: Category.browser.rawValue,
                         action: Action.open.rawValue)
            .label(Label.DefaultBrowser.settings.rawValue))
    }

    // MARK: Menu
    func menuClick(_ item: Analytics.Label.Menu) {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.click.rawValue)
            .label(item.rawValue)
        track(event)
    }

    func menuShare(_ content: Property.ShareContent) {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.click.rawValue)
            .label(Label.Menu.share.rawValue)
            .property(content.rawValue)
        track(event)
    }

    func menuStatus(changed item: Analytics.Label.MenuStatus, to: Bool) {
        let event = Structured(category: Category.menuStatus.rawValue,
                               action: Action.click.rawValue)
            .label(item.rawValue)
            .value(.init(value: to))
        track(event)
    }

    // MARK: Migration
    func migration(_ success: Bool) {
        track(Structured(category: Category.migration.rawValue,
                         action: success ? Action.success.rawValue : Action.error.rawValue))
    }

    func migrationError(in migration: Label.Migration, message: String) {
        track(Structured(category: Category.migration.rawValue,
                         action: Action.error.rawValue)
            .label(migration.rawValue)
            .property(message))
    }

    // MARK: Navigation
    func navigation(_ action: Action, label: Label.Navigation) {
        track(Structured(category: Category.navigation.rawValue,
                         action: action.rawValue)
            .label(label.rawValue))
    }

    func navigationOpenNews(_ id: String) {
        track(Structured(category: Category.navigation.rawValue,
                         action: Action.open.rawValue)
            .label(Label.Navigation.news.rawValue)
            .property(id))
    }

    func navigationChangeMarket(_ new: String) {
        track(Structured(category: Category.navigation.rawValue,
                         action: Action.change.rawValue)
            .label(Label.market.rawValue)
            .property(new))
    }

    // MARK: `NewsletterCardExperiment`
    func newsletterCardExperiment(action: Action.NewsletterCardExperiment) {
        track(Structured(category: Category.newsletterExperiment.rawValue,
                         action: action.rawValue)
            .label(Label.NewsletterCardExperiment.ntpCard.rawValue))
    }

    // MARK: NTP
    func ntpCustomisation(_ action: Action.NTPCustomization, label: Label.NTP) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(label.rawValue))
    }

    func ntpTopSite(_ action: Action.TopSite, property: Property.TopSite, position: NSNumber? = nil) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(Label.NTP.topSites.rawValue)
            .property(property.rawValue)
            .value(position))
    }

    func ntpLibraryItem(_ action: Action, property: Property.Library) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(Label.NTP.quickActions.rawValue)
            .property(property.rawValue))
    }

    func ntpSeedCounterExperiment(_ action: Action.SeedCounter,
                                  value: NSNumber) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(Label.NTP.climateCounter.rawValue)
            .value(value)
        )
    }

    // MARK: Onboarding
    func introDisplaying(page: Property.OnboardingPage?, at index: Int) {
        guard let page else {
            return
        }
        let event = Structured(category: Category.intro.rawValue,
                               action: Action.display.rawValue)
            .property(page.rawValue)
            .value(.init(integerLiteral: index))
        track(event)
    }

    func introClick(_ label: Label.Onboarding, page: Property.OnboardingPage?, index: Int) {
        guard let page else {
            return
        }
        let event = Structured(category: Category.intro.rawValue,
                               action: Action.click.rawValue)
            .label(label.rawValue)
            .property(page.rawValue)
            .value(.init(integerLiteral: index))
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
    func referral(action: Action.Referral, label: Label.Referral? = nil) {
        track(Structured(category: Category.invitations.rawValue,
                         action: action.rawValue)
            .label(label?.rawValue))
    }

    // MARK: Settings
    func searchbarChanged(to position: String) {
        track(Structured(category: Category.settings.rawValue,
                         action: Action.change.rawValue)
            .label(Label.toolbar.rawValue)
            .property(position))
    }

    func sendAnonymousUsageDataSetting(enabled: Bool) {
        // This is the only place where the tracker should be directly
        // used since we want to send this just as the user opts out
        _ = tracker.track(Structured(category: Category.settings.rawValue,
                                     action: Action.change.rawValue)
            .label(Label.analytics.rawValue)
            .property(enabled ? Property.enable.rawValue : Property.disable.rawValue))
    }
}

extension Analytics {
    func appendTestContextIfNeeded(_ action: Analytics.Action.Activity, _ event: Structured, completion: @escaping () -> Void) {
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
}
