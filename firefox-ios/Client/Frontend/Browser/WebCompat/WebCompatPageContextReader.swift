// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

/// The `broken-site-report` fields only the page can answer.
struct WebCompatPageContext: Equatable {
    var languages: [String]?
    var userAgent: String?
    var fastclick: Bool?
    var marfeel: Bool?
    var mobify: Bool?

    /// Spelled out because the initializer below would otherwise take the memberwise one with it.
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

    /// A page can redefine `navigator`, so an empty or wrongly-typed value is dropped per field
    /// rather than reported as real data.
    init(from result: [String: Any]) {
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

protocol WebCompatPageContextReading: Sendable {
    @MainActor
    func read(from tab: Tab) async -> WebCompatPageContext
}

struct WebCompatPageContextReader: WebCompatPageContextReading {
    /// Mirrors `FrameworkDetector` in desktop's `ReportBrokenSiteChild.sys.mjs`. `safe` keeps one
    /// throwing accessor from costing all five fields.
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

    /// `.page`, not the client world, because page scripts set the framework globals. And
    /// `callAsyncJavaScript`, because `evaluateJavaScript` would reject the top-level `return`.
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
