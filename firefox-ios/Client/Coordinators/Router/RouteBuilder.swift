// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import CoreSpotlight
import Shared

final class RouteBuilder {
    private var isPrivate = false
    private var prefs: Prefs?

    func configure(isPrivate: Bool,
                   prefs: Prefs) {
        self.isPrivate = isPrivate
        self.prefs = prefs
    }

    func parseURLHost(_ url: URL) -> DeeplinkInput.Host? {
        guard let urlScanner = URLScanner(url: url), urlScanner.isOurScheme else { return nil }
        return DeeplinkInput.Host(rawValue: urlScanner.host.lowercased())
    }

    func makeRoute(url: URL) -> Route? {
        guard let urlScanner = URLScanner(url: url) else { return nil }

        if let host = parseURLHost(url) {
            let urlQuery = urlScanner.fullURLQueryItem()?.asURL
            // Unless the `open-url` URL specifies a `private` parameter,
            // use the last browsing mode the user was in.
            let isPrivate = Bool(urlScanner.value(query: "private") ?? "") ?? isPrivate

            recordTelemetry(input: host, isPrivate: isPrivate)

            switch host {
            case .deepLink:
                let deepLinkURL = urlScanner.fullURLQueryItem()?.lowercased()
                let paths = deepLinkURL?.split(separator: "/") ?? []
                guard let pathRaw = paths[safe: 0].flatMap(String.init),
                      let path = DeeplinkInput.Path(rawValue: pathRaw),
                      let subPath = paths[safe: 1].flatMap(String.init)
                else { return nil }
                if path == .settings, let subPath = Route.SettingsSection(rawValue: subPath) {
                    return .settings(section: subPath)
                } else if path == .homepanel, let subPath = Route.HomepanelSection(rawValue: subPath) {
                    return .homepanel(section: subPath)
                } else if path == .defaultBrowser, let subPath = Route.DefaultBrowserSection(rawValue: subPath) {
                    return .defaultBrowser(section: subPath)
                } else if path == .action, let subPath = Route.AppAction(rawValue: subPath) {
                    return .action(action: subPath)
                } else {
                    return nil
                }

            case .fxaSignIn where urlScanner.value(query: "signin") != nil:
                return .fxaSignIn(
                    params: FxALaunchParams(
                        entrypoint: .fxaDeepLinkNavigation,
                        query: url.getQuery()
                    )
                )

            case .openUrl:
                // If we have a URL query, then make sure to check its a webpage
                if urlQuery == nil || urlQuery?.isWebPage() ?? false {
                    return .search(url: urlQuery, isPrivate: isPrivate)
                } else {
                    return nil
                }

            case .openText:
                return .searchQuery(query: urlScanner.value(query: "text") ?? "", isPrivate: isPrivate)

            case .glean:
                return .glean(url: url)

            case .widgetMediumTopSitesOpenUrl:
                // Widget Top sites - open url
                return .search(url: urlQuery, isPrivate: isPrivate)

            case .widgetSmallQuickLinkOpenUrl:
                // Widget Quick links - small - open url private or regular
                return .search(url: urlQuery, isPrivate: isPrivate, options: [.focusLocationField])

            case .widgetMediumQuickLinkOpenUrl:
                // Widget Quick Actions - medium - open url private or regular
                return .search(url: urlQuery, isPrivate: isPrivate, options: [.focusLocationField])

            case .widgetSmallQuickLinkOpenCopied, .widgetMediumQuickLinkOpenCopied:
                // Widget Quick links - medium - open copied url
                if !UIPasteboard.general.hasURLs {
                    let searchText = UIPasteboard.general.string ?? ""
                    return .searchQuery(query: searchText, isPrivate: isPrivate)
                } else {
                    let url = UIPasteboard.general.url
                    return .search(url: url, isPrivate: isPrivate)
                }

            case .widgetSmallQuickLinkClosePrivateTabs, .widgetMediumQuickLinkClosePrivateTabs:
                // Widget Quick links - medium - close private tabs
                return .action(action: .closePrivateTabs)

            case .widgetTabsMediumOpenUrl:
                // Widget Tabs Quick View - medium
                let tabs = SimpleTab.getSimpleTabs()
                if let uuid = urlScanner.value(query: "uuid"), !tabs.isEmpty, let tab = tabs[uuid] {
                    return .searchURL(url: tab.url, tabId: uuid)
                } else {
                    return .search(url: nil, isPrivate: false)
                }

            case .widgetTabsLargeOpenUrl:
                // Widget Tabs Quick View - large
                let tabs = SimpleTab.getSimpleTabs()
                if let uuid = urlScanner.value(query: "uuid"), !tabs.isEmpty {
                    let tab = tabs[uuid]
                    return .searchURL(url: tab?.url, tabId: uuid)
                } else {
                    return .search(url: nil, isPrivate: false)
                }

            case .fxaSignIn:
                return nil

            case .sharesheet:
                guard let shareURLString = urlScanner.value(query: "url"),
                      let shareURL = URL(string: shareURLString) else {
                    assertionFailure("Should not be trying to share a bad URL")
                    return nil
                }

                // Pass optional share message and subtitle here
                var shareMessage: ShareMessage?
                if let titleText = urlScanner.value(query: "title") {
                    let subtitleText: String? = urlScanner.value(query: "subtitle")

                    shareMessage = ShareMessage(message: titleText, subtitle: subtitleText)
                }

                // Deeplinks cannot have an associated tab or file, so this must be a website URL `.site` share
                return .sharesheet(shareType: .site(url: shareURL), shareMessage: shareMessage)
            }
        } else if urlScanner.isHTTPScheme {
            TelemetryWrapper.gleanRecordEvent(category: .action, method: .open, object: .asDefaultBrowser)
            RatingPromptManager.isBrowserDefault = true
            // Use the last browsing mode the user was in
            return .search(url: url, isPrivate: isPrivate, options: [.focusLocationField])
        } else {
            return nil
        }
    }

    func makeRoute(userActivity: NSUserActivity) -> Route? {
        // If the user activity is a Siri shortcut to open the app, show a new search tab.
        if userActivity.activityType == SiriShortcuts.activityType.openURL.rawValue {
            return .search(url: nil, isPrivate: false)
        }

        var isBrowseActivity: Bool {
            userActivity.activityType == NSUserActivityTypeBrowsingWeb || userActivity.activityType == browsingActivityType
        }

        // If the user activity has a webpageURL, it's a deep link or an old history item.
        // Use the URL to create a new search tab.
        if let url = userActivity.webpageURL,
           isBrowseActivity {
            return .search(url: url, isPrivate: false)
        }

        // If the user activity is a CoreSpotlight item, check its activity identifier to determine
        // which URL to open.
        if userActivity.activityType == CSSearchableItemActionType {
            guard let userInfo = userActivity.userInfo,
                  let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                  let url = URL(string: urlString, invalidCharacters: false)
            else {
                return nil
            }
            return .search(url: url, isPrivate: false)
        }

        // If the user activity does not match any of the above criteria, return nil to indicate that
        // the route could not be determined.
        return nil
    }

    func makeRoute(shortcutItem: UIApplicationShortcutItem, tabSetting: NewTabPage) -> Route? {
        guard let shortcutTypeRaw = shortcutItem.type.components(separatedBy: ".").last,
              let shortcutType = DeeplinkInput.Shortcut(rawValue: shortcutTypeRaw)
        else { return nil }

        let options: Set<Route.SearchOptions> = tabSetting != .homePage ? [.focusLocationField] : []

        switch shortcutType {
        case .newTab:
            return .search(url: nil, isPrivate: false, options: options)
        case .newPrivateTab:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .newPrivateTab,
                                         value: .appIcon)
            return .search(url: nil, isPrivate: true, options: options)
        case .openLastBookmark:
            if let urlToOpen = (shortcutItem.userInfo?[QuickActionInfos.tabURLKey] as? String)?.asURL {
                return .search(url: urlToOpen, isPrivate: isPrivate)
            } else {
                return nil
            }
        case .qrCode:
            return .action(action: .showQRCode)
        }
    }

    // MARK: - Telemetry

    private func recordTelemetry(input: DeeplinkInput.Host, isPrivate: Bool) {
        switch input {
        case .deepLink, .fxaSignIn, .glean, .sharesheet:
            return
        case .widgetMediumTopSitesOpenUrl:
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .mediumTopSitesWidget)
        case .widgetSmallQuickLinkOpenUrl:
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .smallQuickActionSearch)
        case .widgetMediumQuickLinkOpenUrl:
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .open,
                object: isPrivate ?.mediumQuickActionPrivateSearch:.mediumQuickActionSearch
            )
        case .widgetSmallQuickLinkOpenCopied:
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .smallQuickActionClosePrivate)
        case .widgetMediumQuickLinkOpenCopied:
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .mediumQuickActionClosePrivate)
        case .widgetSmallQuickLinkClosePrivateTabs:
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .smallQuickActionClosePrivate)
        case .widgetMediumQuickLinkClosePrivateTabs:
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .mediumQuickActionClosePrivate)
        case .widgetTabsMediumOpenUrl:
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .mediumTabsOpenUrl)
        case .widgetTabsLargeOpenUrl:
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .largeTabsOpenUrl)
        case .openText:
            sendAppExtensionTelemetry(object: .searchText)
        case .openUrl:
            sendAppExtensionTelemetry(object: .url)
        }
    }

    private func sendAppExtensionTelemetry(object: TelemetryWrapper.EventObject) {
        if prefs?.boolForKey(PrefsKeys.AppExtensionTelemetryOpenUrl) != nil {
            prefs?.removeObjectForKey(PrefsKeys.AppExtensionTelemetryOpenUrl)
            TelemetryWrapper.recordEvent(category: .appExtensionAction,
                                         method: .applicationOpenUrl,
                                         object: object)
        }
    }
}
