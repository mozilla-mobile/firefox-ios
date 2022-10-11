import Foundation
import SnowplowTracker
import Core

final class Analytics {
    private static var tracker: TrackerController {
        Snowplow
            .createTracker(namespace: "ios_sp",
                           network: .init(endpoint: Environment.current.snowplow),
                           configurations: [TrackerConfiguration()
                                                .appId(Bundle.version)
                                                .platformContext(true)
                                                .geoLocationContext(true),
                                            SubjectConfiguration()
                                                .userId(User.shared.analyticsId.uuidString)])
    }
    
    static let shared = Analytics()
    private(set) var tracker: TrackerController

    private init() {
        tracker = Self.tracker
        tracker.screenViewAutotracking = false
        tracker.lifecycleAutotracking = false
        tracker.installAutotracking = false
    }
    
    func install() {
        tracker
            .track(SelfDescribing(schema: "iglu:org.ecosia/ios_install_event/jsonschema/1-0-0",
                                  payload: ["app_v": Bundle.version as NSObject]))
    }
    
    func reset() {
        User.shared.analyticsId = .init()
        tracker = Self.tracker
    }
    
    func activity(_ action: Action.Activity) {
        tracker
            .track(Structured(category: Category.activity.rawValue,
                              action: action.rawValue)
                    .label("inapp"))
    }

    func browser(_ action: Action.Browser, label: Label.Browser, property: Property? = nil) {
        tracker
            .track(Structured(category: Category.browser.rawValue,
                              action: action.rawValue)
                    .label(label.rawValue)
                    .property(property?.rawValue))
    }

    func navigation(_ action: Action, label: Label.Navigation) {
        tracker
            .track(Structured(category: Category.navigation.rawValue,
                              action: action.rawValue)
                    .label(label.rawValue))
    }

    func navigationOpenNews(_ id: String) {
        tracker
            .track(Structured(category: Category.navigation.rawValue,
                              action: Action.open.rawValue)
                    .label(Label.Navigation.news.rawValue)
                    .property(id))
    }
    
    func navigationChangeMarket(_ new: String) {
        tracker
            .track(Structured(category: Category.navigation.rawValue,
                              action: "change")
                    .label("market")
                    .property(new))
    }

    func deeplink() {
        tracker
            .track(Structured(category: Category.external.rawValue,
                              action: Action.receive.rawValue)
                    .label("deeplink"))
    }
    
    func defaultBrowser() {
        tracker
            .track(Structured(category: Category.external.rawValue,
                              action: Action.receive.rawValue)
                    .label("default_browser_deeplink"))
    }
    
    func defaultBrowser(_ action: Action.Promo) {
        tracker
            .track(Structured(category: Category.browser.rawValue,
                              action: action.rawValue)
                    .label("default_browser_promo")
                    .property("home"))
    }

    func defaultBrowserSettings() {
        tracker
            .track(Structured(category: Category.browser.rawValue,
                              action: Action.open.rawValue)
                    .label("default_browser_settings"))
    }

    func migration(_ success: Bool) {
        tracker
            .track(Structured(category: Category.migration.rawValue,
                              action: success ? Action.success.rawValue : Action.error.rawValue))
    }

    func migrationError(in migration: Migration, message: String) {
        tracker
            .track(Structured(category: Category.migration.rawValue,
                              action: Action.error.rawValue)
                    .label(migration.rawValue)
                    .property(message))
    }

    func migrationRetryHistory(_ success: Bool) {
        tracker
            .track(Structured(category: Category.migration.rawValue,
                              action: Action.retry.rawValue)
                    .label(Migration.history.rawValue)
                    .property(success ? Action.success.rawValue : Action.error.rawValue))
    }
    
    func migrated(_ migration: Migration, in seconds: TimeInterval) {
        tracker
            .track(Structured(category: Category.migration.rawValue,
                              action: Action.completed.rawValue)
                    .label(migration.rawValue)
                    .value(.init(value: seconds * 1000)))
    }
    
    func open(topSite: Property.TopSite) {
        tracker
            .track(Structured(category: Category.browser.rawValue,
                              action: Action.open.rawValue)
                    .label("top_sites")
                    .property(topSite.rawValue))
    }
    
    func openInvitations() {
        tracker
            .track(Structured(category: Category.invitations.rawValue,
                              action: Action.view.rawValue)
                    .label("invite_screen"))
    }

    func startInvite() {
        tracker
            .track(Structured(category: Category.invitations.rawValue,
                              action: Action.click.rawValue)
                    .label("invite"))
    }
    
    func sendInvite() {
        tracker
            .track(Structured(category: Category.invitations.rawValue,
                              action: Action.send.rawValue)
                    .label("invite"))
    }

    func showInvitePromo() {
        tracker
            .track(Structured(category: Category.invitations.rawValue,
                              action: Action.view.rawValue)
                    .label("promo"))
    }

    func openInvitePromo() {
        tracker
            .track(Structured(category: Category.invitations.rawValue,
                              action: Action.open.rawValue)
                    .label("promo"))
    }

    func inviteClaimSuccess() {
        tracker
            .track(Structured(category: Category.invitations.rawValue,
                              action: Action.claim.rawValue))
    }

    func inviteLearnMore() {
        tracker
            .track(Structured(category: Category.invitations.rawValue,
                              action: Action.click.rawValue)
                    .label("learn_more"))
    }
    
    func clickYourImpact(on category: Category) {
        tracker
            .track(Structured(category: category.rawValue,
                              action: Action.click.rawValue)
                    .label("your_impact"))
    }

    func searchbarChanged(to position: String) {
        tracker
            .track(Structured(category: Category.browser.rawValue,
                              action: Action.change.rawValue)
                .label(Label.Browser.searchbar.rawValue)
                .property(position))
    }
}
