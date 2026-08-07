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

    /// Reads the evaluation result, dropping anything the page returned in a shape the ping
    /// can't carry. A page can redefine `navigator`, so nothing here is assumed well-formed.
    static func make(from result: [String: Any]) -> WebCompatPageContext {
        var context = WebCompatPageContext()
        context.languages = (result["languages"] as? [Any])?.compactMap { $0 as? String }
        context.userAgent = (result["userAgent"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        context.fastclick = result["fastclick"] as? Bool
        context.marfeel = result["marfeel"] as? Bool
        context.mobify = result["mobify"] as? Bool
        return context
    }
}

/// Reads the page context with one evaluation at report time, rather than injecting a user
/// script on every page load for values only a report needs.
@MainActor
enum WebCompatPageContextReader {
    /// Mirrors `FrameworkDetector` in desktop's `ReportBrokenSiteChild.sys.mjs`, including the
    /// prototype scan for FastClick, so the two platforms report the same thing.
    private static let script = """
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
      languages: Array.from(navigator.languages || []),
      userAgent: navigator.userAgent,
      fastclick: hasFastClick(window),
      marfeel: !!window.marfeel,
      mobify: !!window.Mobify?.Tag
    };
    """

    /// Runs in `WKContentWorld.page`, not the client world: the framework globals are set
    /// by page scripts, and an isolated world has its own JS global where they aren't visible.
    /// Desktop reaches the same objects through `window.wrappedJSObject`.
    ///
    /// `callAsyncJavaScript` rather than `evaluateJavaScript` because the script is a function
    /// body: `evaluateJavaScript` runs its string as a program, where the top-level `return`
    /// above is a syntax error that this method would swallow into an empty context.
    static func read(
        from webView: WKWebView,
        logger: Logger = DefaultLogger.shared
    ) async -> WebCompatPageContext {
        do {
            let result = try await webView.callAsyncJavaScript(script, contentWorld: .page)
            guard let dictionary = result as? [String: Any] else {
                logger.log("WebCompat page context returned an unexpected value",
                           level: .warning,
                           category: .webview)
                return WebCompatPageContext()
            }
            return WebCompatPageContext.make(from: dictionary)
        } catch {
            logger.log("WebCompat page context failed: \(error.localizedDescription)",
                       level: .warning,
                       category: .webview)
            return WebCompatPageContext()
        }
    }
}
