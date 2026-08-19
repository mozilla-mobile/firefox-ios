// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

/// The `broken-site-report` fields only the page can answer: the `navigator` values it sees
/// and the globals desktop's `FrameworkDetector` looks for.
struct WebCompatPageContext: Equatable {
    var languages: [String]?
    var userAgent: String?
    var fastclick: Bool?
    var marfeel: Bool?
    var mobify: Bool?

    /// Spelled out because the initializer below would otherwise take the synthesized
    /// memberwise one with it, and the tests build contexts field by field.
    init(
        languages: [String]? = nil,
        userAgent: String? = nil,
        fastclick: Bool? = nil,
        marfeel: Bool? = nil,
        mobify: Bool? = nil
    ) {
        self.languages = languages
        self.userAgent = userAgent
        self.fastclick = fastclick
        self.marfeel = marfeel
        self.mobify = mobify
    }

    /// Reads the evaluation result, dropping anything the page returned in a shape the ping
    /// can't carry. A page can redefine `navigator`, so nothing here is assumed well-formed.
    init(from result: [String: Any]) {
        // An empty list would be recorded as real data, the trap the empty user agent avoids.
        if let pageLanguages = (result["languages"] as? [Any])?.compactMap({ $0 as? String }),
           !pageLanguages.isEmpty {
            languages = pageLanguages
        }
        userAgent = (result["userAgent"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        fastclick = result["fastclick"] as? Bool
        marfeel = result["marfeel"] as? Bool
        mobify = result["mobify"] as? Bool
    }
}

/// A page-context read, behind a protocol so tests can stand in for the JavaScript round trip
/// without a live `WKWebView`.
protocol WebCompatPageContextReading: Sendable {
    @MainActor
    func read(from tab: Tab) async -> WebCompatPageContext
}

/// Reads the page context with one evaluation, rather than injecting a user script on every
/// page load for values only a report needs.
struct WebCompatPageContextReader: WebCompatPageContextReading {
    /// Mirrors `FrameworkDetector` in desktop's `ReportBrokenSiteChild.sys.mjs`, including the
    /// prototype scan for FastClick, so the two platforms report the same thing. Each field is
    /// wrapped in `safe` so one throwing accessor costs that field rather than all five.
    private static let script = """
    function safe(read) {
      try { return read(); } catch (_) { return undefined; }
    }
    function hasFastClick(win) {
      if (win.FastClick) { return true; }
      for (const property in win) {
        try {
          const proto = win[property].prototype;
          if (proto && proto.needsClick) { return true; }
        } catch (_) {}
      }
      return false;
    }
    return {
      languages: safe(() => Array.from(navigator.languages || [])),
      userAgent: safe(() => navigator.userAgent),
      fastclick: safe(() => hasFastClick(window)),
      marfeel: safe(() => !!window.marfeel),
      mobify: safe(() => !!window.Mobify?.Tag)
    };
    """

    private let logger: Logger = DefaultLogger.shared

    /// Runs in `WKContentWorld.page`, not the client world: the framework globals are set
    /// by page scripts, and an isolated world has its own JS global where they aren't visible.
    /// Desktop reaches the same objects through `window.wrappedJSObject`.
    ///
    /// `callAsyncJavaScript`, not the ticket's `evaluateJavaScript`, because the script is a
    /// function body and a top-level `return` is a syntax error in a program string.
    @MainActor
    func read(from tab: Tab) async -> WebCompatPageContext {
        guard let webView = tab.webView else {
            logger.log("WebCompat page context skipped: tab has no web view",
                       level: .warning,
                       category: .webview)
            return WebCompatPageContext()
        }
        do {
            let result = try await webView.callAsyncJavaScript(
                WebCompatPageContextReader.script,
                contentWorld: .page
            )
            guard let dictionary = result as? [String: Any] else {
                logger.log("WebCompat page context returned an unexpected value",
                           level: .warning,
                           category: .webview)
                return WebCompatPageContext()
            }
            return WebCompatPageContext(from: dictionary)
        } catch {
            logger.log("WebCompat page context failed: \(error.localizedDescription)",
                       level: .warning,
                       category: .webview)
            return WebCompatPageContext()
        }
    }
}
