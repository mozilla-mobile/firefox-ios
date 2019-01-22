/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct FxALaunchParams {
    var query: [String: String]
}

// An enum to route to HomePanels
enum HomePanelPath: String {
    case bookmarks
    case topsites
    case readingList
    case history
}

// An enum to route to a settings page.
// This could be extended to provide default values to pass to fxa
enum SettingsPage: String {
    case newTab
    case homePage
    case mailto
    case search
    case clearData = "clear-private-data"
    case fxa
    case theme
    case translation
}

// Used by the App to navigate to different views.
// To open a URL use /open-url or to open a blank tab use /open-url with no params
enum DeepLink {
    case settings(SettingsPage)
    case homePanel(HomePanelPath)
    init?(urlString: String) {
        let paths = urlString.split(separator: "/")
        guard let component = paths[safe: 0], let componentPath = paths[safe: 1] else {
            return nil
        }
        if component == "settings", let link = SettingsPage(rawValue: String(componentPath)) {
            self = .settings(link)
        } else if component == "homepanel", let link = HomePanelPath(rawValue: String(componentPath)) {
            self = .homePanel(link)
        } else {
            return nil
        }
    }
}

extension URLComponents {
    // Return the first query parameter that matches
    func valueForQuery(_ param: String) -> String? {
        return self.queryItems?.first { $0.name == param }?.value
    }
}

// The root navigation for the Router. Look at the tests to see a complete URL
enum NavigationPath {
    case url(webURL: URL?, isPrivate: Bool)
    case fxa(params: FxALaunchParams)
    case deepLink(DeepLink)
    case text(String)

    init?(url: URL) {
        let urlString = url.absoluteString
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
            let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String] else {
            // Something very strange has happened; org.mozilla.Client should be the zeroeth URL type.
            return nil
        }

        guard let scheme = components.scheme, urlSchemes.contains(scheme) else {
            return nil
        }

        if urlString.starts(with: "\(scheme)://deep-link"), let deepURL = components.valueForQuery("url"), let link = DeepLink(urlString: deepURL) {
            self = .deepLink(link)
        } else if urlString.starts(with: "\(scheme)://fxa-signin"), components.valueForQuery("signin") != nil {
            self = .fxa(params: FxALaunchParams(query: url.getQuery()))
        } else if urlString.starts(with: "\(scheme)://open-url") {
            let url = components.valueForQuery("url")?.asURL
            // Unless the `open-url` URL specifies a `private` parameter,
            // use the last browsing mode the user was in.
            let isPrivate = Bool(components.valueForQuery("private") ?? "") ?? UserDefaults.standard.bool(forKey: "isPrivate")
            self = .url(webURL: url, isPrivate: isPrivate)
        } else if urlString.starts(with: "\(scheme)://open-text") {
            let text = components.valueForQuery("text")
            self = .text(text ?? "")
        } else {
            return nil
        }
    }

    static func handle(nav: NavigationPath, with bvc: BrowserViewController) {
        switch nav {
        case .fxa(let params): NavigationPath.handleFxA(params: params, with: bvc)
        case .deepLink(let link): NavigationPath.handleDeepLink(link, with: bvc)
        case .url(let url, let isPrivate): NavigationPath.handleURL(url: url, isPrivate: isPrivate, with: bvc)
        case .text(let text): NavigationPath.handleText(text: text, with: bvc)
        }
    }

    private static func handleDeepLink(_ link: DeepLink, with bvc: BrowserViewController) {
        switch link {
        case .homePanel(let panelPath):
            NavigationPath.handleHomePanel(panel: panelPath, with: bvc)
        case .settings(let settingsPath):
            guard let rootVC = bvc.navigationController else {
                return
            }
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = bvc.profile
            settingsTableViewController.tabManager = bvc.tabManager
            settingsTableViewController.settingsDelegate = bvc
            NavigationPath.handleSettings(settings: settingsPath, with: rootVC, baseSettingsVC: settingsTableViewController, and: bvc)
        }
    }

    private static func handleFxA(params: FxALaunchParams, with bvc: BrowserViewController) {
        bvc.presentSignInViewController(params)
    }

    private static func handleHomePanel(panel: HomePanelPath, with bvc: BrowserViewController) {
        switch panel {
        case .bookmarks: bvc.openURLInNewTab(HomePanelType.bookmarks.internalUrl, isPrivileged: true)
        case .history: bvc.openURLInNewTab(HomePanelType.history.internalUrl, isPrivileged: true)
        case .readingList:bvc.openURLInNewTab(HomePanelType.readingList.internalUrl, isPrivileged: true)
        case .topsites: bvc.openURLInNewTab(HomePanelType.topSites.internalUrl, isPrivileged: true)
        }
    }

    private static func handleURL(url: URL?, isPrivate: Bool, with bvc: BrowserViewController) {
        if let newURL = url {
            bvc.switchToTabForURLOrOpen(newURL, isPrivate: isPrivate, isPrivileged: false)
        } else {
            bvc.openBlankNewTab(focusLocationField: true, isPrivate: isPrivate)
        }
        LeanPlumClient.shared.track(event: .openedNewTab, withParameters: ["Source": "External App or Extension"])
    }

    private static func handleText(text: String, with bvc: BrowserViewController) {
        bvc.openBlankNewTab(focusLocationField: false)
        bvc.urlBar(bvc.urlBar, didSubmitText: text)
    }

    private static func handleSettings(settings: SettingsPage, with rootNav: UINavigationController, baseSettingsVC: AppSettingsTableViewController, and bvc: BrowserViewController) {

        guard let profile = baseSettingsVC.profile, let tabManager = baseSettingsVC.tabManager else {
            return
        }

        let controller = ThemedNavigationController(rootViewController: baseSettingsVC)
        controller.popoverDelegate = bvc
        controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
        rootNav.present(controller, animated: true, completion: nil)

        switch settings {
        case .newTab, .homePage:
            let viewController = NewTabContentSettingsViewController(prefs: baseSettingsVC.profile.prefs)
            controller.pushViewController(viewController, animated: true)
        case .mailto:
            let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
            controller.pushViewController(viewController, animated: true)
        case .search:
            let viewController = SearchSettingsTableViewController()
            viewController.model = profile.searchEngines
            viewController.profile = profile
            controller.pushViewController(viewController, animated: true)
        case .clearData:
            let viewController = ClearPrivateDataTableViewController()
            viewController.profile = profile
            viewController.tabManager = tabManager
            controller.pushViewController(viewController, animated: true)
        case .fxa:
            bvc.presentSignInViewController()
        case .theme:
            controller.pushViewController(ThemeSettingsController(), animated: true)
        case .translation:
            controller.pushViewController(TranslationSettingsController(profile), animated: true)
        }
    }
}

extension NavigationPath: Equatable {}

func == (lhs: NavigationPath, rhs: NavigationPath) -> Bool {
    switch (lhs, rhs) {
    case let (.url(lhsURL, lhsPrivate), .url(rhsURL, rhsPrivate)):
        return lhsURL == rhsURL && lhsPrivate == rhsPrivate
    case let (.fxa(lhs), .fxa(rhs)):
        return lhs.query == rhs.query
    case let (.deepLink(lhs), .deepLink(rhs)):
        return lhs == rhs
    default:
        return false
    }
}

extension DeepLink: Equatable {}

func == (lhs: DeepLink, rhs: DeepLink) -> Bool {
    switch (lhs, rhs) {
    case let (.settings(lhs), .settings(rhs)):
        return lhs == rhs
    case let (.homePanel(lhs), .homePanel(rhs)):
        return lhs == rhs
    default:
        return false
    }
}
