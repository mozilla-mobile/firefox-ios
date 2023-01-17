// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

enum NavigationPath {
    case url(_ url: URL)
    case text(_ text: String)
    case widget
    case glean(url: URL)

    init?(url: URL) {
        func sanitizedURL(for unsanitized: URL) -> URL {
            guard var components = URLComponents(url: unsanitized, resolvingAgainstBaseURL: true),
                  let scheme = components.scheme, !scheme.isEmpty
            else { return unsanitized }

            components.scheme = scheme.lowercased()
            return components.url ?? unsanitized
        }

        func unescape(string: String?) -> String? {
            guard let string = string else { return nil }
            return CFURLCreateStringByReplacingPercentEscapes(
                kCFAllocatorDefault,
                string as CFString,
                "" as CFString) as String
        }

        let url = sanitizedURL(for: url)

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
              let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String] else {
            // Something very strange has happened; org.mozilla.Blockzilla should be the zeroeth URL type.
            return nil
        }

        guard let scheme = components.scheme,
              let host = url.host,
              urlSchemes.contains(scheme) else { return nil }

        let query = URL.getQuery(url: url)
        let isHttpScheme = scheme == "http" || scheme == "https"

        if isHttpScheme {
            GleanMetrics.App.openedAsDefaultBrowser.add()
            self = .url(url)
        }
        else if host == "widget" {
            self = .widget
        }
        else if host == "open-url" {
            let urlString = unescape(string: query["url"]) ?? ""
            guard let url = URL(string: urlString) else { return nil }
            self = .url(url)
        } else if host == "open-text" || isHttpScheme {
            let text = unescape(string: query["text"]) ?? ""
            self = .text(text)
        } else if host == "glean" {
            self = .glean(url: url)
        } else { return nil }
    }

    static func handle(_ application: UIApplication, navigation: NavigationPath, with browserViewController: BrowserViewController) -> Any? {
        switch navigation {
        case .url(let url): return NavigationPath.handleURL(application, url: url, with: browserViewController)
        case .text(let text): return NavigationPath.handleText(application, text: text, with: browserViewController)
        case .glean(let url): NavigationPath.handleGlean(url: url)
        case .widget: return NavigationPath.handleWidget(application, with: browserViewController)
        }
        return nil
    }

    private static func handleURL(_ application: UIApplication, url: URL, with browserViewController: BrowserViewController) -> URL? {
        if application.applicationState == .active {
            browserViewController.submit(url: url, source: .action)
        }
        else { return url }
        return nil
    }

    private static func handleText(_ application: UIApplication, text: String, with browserViewController: BrowserViewController) -> String? {
        if application.applicationState == .active {
            if let fixedUrl = URIFixup.getURL(entry: text) {
                browserViewController.submit(url: fixedUrl, source: .action)
            } else {
                browserViewController.submit(text: text, source: .action)
            }
        }
        else { return text }
        return nil
    }

    private static func handleGlean(url: URL) {
        Glean.shared.handleCustomUrl(url: url)
    }

    private static func handleWidget(_ application: UIApplication, with browserViewController: BrowserViewController) {
        browserViewController.openFromWidget()
    }
}

// MARK: - Extensions
extension NavigationPath: Equatable {
    static func == (lhs: NavigationPath, rhs: NavigationPath) -> Bool {
        switch (lhs, rhs) {
        case let (.url(lhsURL), .url(rhsURL)):
            return lhsURL == rhsURL
        case let (.text(lhsText), .text(text: rhsText)):
            return lhsText == rhsText
        case (.widget, .widget):
            return true
        default:
            return false
        }
    }
}
