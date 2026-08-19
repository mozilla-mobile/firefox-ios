// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

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
    private static let scriptResource = "WebCompatPageContext"

    private let logger: Logger = DefaultLogger.shared

    /// Runs in `.page` rather than the client world, because page scripts set the framework globals.
    @MainActor
    func read(from tab: Tab) async -> WebCompatPageContext {
        guard let webView = tab.webView, let script = loadScript() else {
            return WebCompatPageContext()
        }
        do {
            let result = try await webView.evaluateJavaScript(script, in: nil, in: .page)
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

    private func loadScript() -> String? {
        guard let url = Bundle.main.url(forResource: WebCompatPageContextReader.scriptResource,
                                        withExtension: "js"),
              let script = try? String(contentsOf: url, encoding: .utf8) else {
            logger.log("WebCompat page context script is missing from the bundle",
                       level: .warning,
                       category: .webview)
            return nil
        }
        return script
    }
}
