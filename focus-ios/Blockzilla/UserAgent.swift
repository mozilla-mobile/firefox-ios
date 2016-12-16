/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class UserAgent {
    static var browserUserAgent: String?

    static func setup() {
        assert(Thread.current.isMainThread, "UserAgent.setup() must be called on the main thread")

        if let cachedUserAgent = UserAgent.cachedUserAgent() {
            setUserAgent(userAgent: cachedUserAgent)
            return
        }

        guard let userAgent = UserAgent.generateUserAgent() else {
            return
        }

        UserDefaults.standard.set(userAgent, forKey: "UserAgent")
        UserDefaults.standard.set(UIDevice.current.systemVersion, forKey: "LastSeenSystemVersion")
        UserDefaults.standard.synchronize()

        setUserAgent(userAgent: userAgent)
    }

    private static func cachedUserAgent() -> String? {
        guard let lastSeenSystemVersion = UserDefaults.standard.string(forKey: "LastSeenSystemVersion") else {
            return nil
        }

        if lastSeenSystemVersion != UIDevice.current.systemVersion {
            return nil
        }

        return UserDefaults.standard.string(forKey: "UserAgent")
    }

    private static func generateUserAgent() -> String? {
        let webView = UIWebView()
        guard var webViewUserAgent = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent") else {
            return nil
        }

        // Insert our product/version identifier before the Mobile identifier.
        if let range = webViewUserAgent.range(of: "Mobile/") {
            let identifier = "\(AppInfo.config.productName)/\(AppInfo.shortVersion) "
            webViewUserAgent.insert(contentsOf: identifier.characters, at: range.lowerBound)
        }

        return webViewUserAgent
    }

    private static func setUserAgent(userAgent: String) {
        UserDefaults.standard.register(defaults: ["UserAgent": userAgent])
        UserDefaults.standard.synchronize()
    }
}
