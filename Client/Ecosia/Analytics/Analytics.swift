import Foundation
import SnowplowTracker
import Core

final class Analytics {
    private static let installSchema = "iglu:org.ecosia/ios_install_event/jsonschema/1-0-0"
    private static let abTestSchema = "iglu:org.ecosia/abtest_context/jsonschema/1-0-1"
    private static let abTestRoot = "ab_tests"
    private static let namespace = "ios_sp"
    
    private static var tracker: TrackerController {
                
        return Snowplow.createTracker(namespace: namespace,
                                      network: .init(endpoint: Environment.current.urlProvider.snowplow),
                                      configurations: [Self.trackerConfiguration,
                                                       Self.subjectConfiguration,
                                                       Self.appResumeDailyTrackingPluginConfiguration])!
    }
    
    static let shared = Analytics()
    private var tracker: TrackerController
    
    private init() {
        tracker = Self.tracker
        tracker.installAutotracking = true
        tracker.screenViewAutotracking = false
        tracker.lifecycleAutotracking = false
        tracker.exceptionAutotracking = false
        tracker.diagnosticAutotracking = false
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
    
    func install() {
        track(SelfDescribing(schema: Self.installSchema,
                             payload: ["app_v": Bundle.version as NSObject]))
    }
    
    func reset() {
        User.shared.analyticsId = .init()
        tracker = Self.tracker
    }
    
    func activity(_ action: Action.Activity) {
        let event = Structured(category: Category.activity.rawValue,
                               action: action.rawValue)
            .label(Analytics.Label.Navigation.inapp.rawValue)
        
        switch action {
        case .resume, .launch:
            // add A/B Test context
            if let context = Self.getTestContext(from: .searchShortcuts) {
                event.contexts.append(context)
            }
        }

        track(event)
    }
    
    func browser(_ action: Action.Browser, label: Label.Browser, property: Property? = nil) {
        track(Structured(category: Category.browser.rawValue,
                         action: action.rawValue)
            .label(label.rawValue)
            .property(property?.rawValue))
    }
    
    func ntp(_ action: Action, label: Label.NTP) {
        track(Structured(category: Category.ntp.rawValue,
                         action: action.rawValue)
            .label(label.rawValue))
    }
    
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
                         action: "change")
            .label("market")
            .property(new))
    }
    
    func deeplink() {
        track(Structured(category: Category.external.rawValue,
                         action: Action.receive.rawValue)
            .label("deeplink"))
    }
    
    func appOpenAsDefaultBrowser() {
        let event = Structured(category: Category.external.rawValue,
                               action: Action.receive.rawValue)
            .label("default_browser_deeplink")
        
        // add A/B Test context
        if let context = Self.getTestContext(from: .defaultBrowser) {
            event.contexts.append(context)
        }
        
        track(event)
    }
    
    func defaultBrowser(_ action: Action.Promo) {
        let event = Structured(category: Category.browser.rawValue,
                               action: action.rawValue)
            .label("default_browser_promo")
            .property("home")
        
        // add A/B Test context
        if let context = Self.getTestContext(from: .defaultBrowser) {
            event.contexts.append(context)
        }
        
        track(event)
    }
    
    /// Sends the analytics event for a given action
    /// The function is EngagementService agnostic e.g. doesn't have context
    /// of the engagement service being used (i.e. `Braze`)
    /// but it does get the `Toggle.Name` from the one
    /// defined in the `APNConsentUIExperiment`
    /// so to leverage decoupling.
    func apnConsent(_ action: Action.APNConsent) {
        let event = Structured(category: Category.pushNotification.rawValue,
                               action: action.rawValue)
            .label("push_notification_consent")
            .property(Property.home.rawValue)
        
        // Add context (if any) from current EngagementService enabled
        if let toggleName = Unleash.Toggle.Name(rawValue: EngagementServiceExperiment.toggleName),
           let context = Self.getTestContext(from: toggleName) {
            event.contexts.append(context)
        }
        
        track(event)
    }
    
    func accessQuickSearchSettingsScreen() {
        let event = Structured(category: Category.browser.rawValue,
                               action: Action.open.rawValue)
            .label("quick_search_settings")

        track(event)
    }
    
    func addsNewSearchEngineInQuickSearchSettingsScreen(_ searchEngine: String) {
        let event = Structured(category: Category.browser.rawValue,
                               action: "add")
            .label("search_engine")
            .property(searchEngine)

        track(event)
    }
        
    func defaultBrowserSettings() {
        track(Structured(category: Category.browser.rawValue,
                         action: Action.open.rawValue)
            .label("default_browser_settings"))
    }
    
    func migration(_ success: Bool) {
        track(Structured(category: Category.migration.rawValue,
                         action: success ? Action.success.rawValue : Action.error.rawValue))
    }
    
    func migrationError(in migration: Migration, message: String) {
        track(Structured(category: Category.migration.rawValue,
                         action: Action.error.rawValue)
            .label(migration.rawValue)
            .property(message))
    }
    
    func migrationRetryHistory(_ success: Bool) {
        track(Structured(category: Category.migration.rawValue,
                         action: Action.retry.rawValue)
            .label(Migration.history.rawValue)
            .property(success ? Action.success.rawValue : Action.error.rawValue))
    }
    
    func migrated(_ migration: Migration, in seconds: TimeInterval) {
        track(Structured(category: Category.migration.rawValue,
                         action: Action.completed.rawValue)
            .label(migration.rawValue)
            .value(.init(value: seconds * 1000)))
    }
    
    func openInvitations() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.view.rawValue)
            .label("invite_screen"))
    }
    
    func startInvite() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.click.rawValue)
            .label("invite"))
    }
    
    func sendInvite() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.send.rawValue)
            .label("invite"))
    }
    
    func showInvitePromo() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.view.rawValue)
            .label("promo"))
    }
    
    func openInvitePromo() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.open.rawValue)
            .label("promo"))
    }
    
    func inviteClaimSuccess() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.claim.rawValue))
    }
    
    func inviteCopy() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.click.rawValue)
            .label("link_copying"))
    }
    
    func inviteLearnMore() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.click.rawValue)
            .label("learn_more"))
    }
    
    func searchbarChanged(to position: String) {
        track(Structured(category: Category.settings.rawValue,
                         action: Action.change.rawValue)
            .label("toolbar")
            .property(position))
    }
    
    func menuClick(_ item: String) {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.click.rawValue)
            .label(item)
        track(event)
    }
    
    func menuStatus(changed item: String, to: Bool) {
        let event = Structured(category: Category.menuStatus.rawValue,
                               action: Action.click.rawValue)
            .label(item)
            .value(.init(value: to))
        track(event)
    }
    
    func menuShare(_ content: ShareContent) {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.click.rawValue)
            .label("share")
            .property(content.rawValue)
        track(event)
    }

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
    
    func bookmarksNtp(action: Action.Promo) {
        let event = Structured(category: Category.bookmarks.rawValue,
                               action: action.rawValue)
            .label(Label.Bookmarks.bookmarksPromo.rawValue)
        track(event)
    }
    
    func bookmarksImportEnded(_ property: Property.Bookmarks) {
        let event = Structured(category: Category.bookmarks.rawValue,
                               action: Action.Bookmarks.import.rawValue)
            .label(Label.Bookmarks.import.rawValue)
            .property(property.rawValue)
        track(event)
    }
    
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
    
    func introClick(_ label: Label.Navigation, page: Property.OnboardingPage?, index: Int) {
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
    
    func sendAnonymousUsageDataSetting(enabled: Bool) {
        // This is the only place where the tracker should be directly
        // used since we want to send this just as the user opts out
        _ = tracker.track(Structured(category: Category.settings.rawValue,
                                     action: Action.change.rawValue)
            .label("analytics")
            .property(enabled ? "enable" : "disable"))
    }
}
