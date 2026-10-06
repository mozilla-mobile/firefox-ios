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
    /// The function `WebCompatPageContext.js` puts on the page-world `window`.
    private static let scriptCall = "return window.__firefoxWebCompat__.getPageContext();"

    private let logger: Logger = DefaultLogger.shared

    /// The script ships in `WebcompatAllFramesAtDocumentStart.js`, which is injected in the page
    /// content world rather than the client one, because page scripts set the framework globals.
    @MainActor
    func read(from tab: Tab) async -> WebCompatPageContext {
        guard let webView = tab.webView else { return WebCompatPageContext() }
        do {
            let result = try await webView.callAsyncJavaScript(
                WebCompatPageContextReader.scriptCall,
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
