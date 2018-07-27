/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class UserAgent {
    static let shared = UserAgent()

    private var userDefaults: UserDefaults

    var browserUserAgent: String?

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        setup()
    }

    func setup() {
        if let cachedUserAgent = cachedUserAgent() {
            setUserAgent(userAgent: cachedUserAgent)
            return
        }

        guard let userAgent = UserAgent.generateUserAgent() else {
            return
        }

        userDefaults.set(userAgent, forKey: "UserAgent")
        userDefaults.set(UIDevice.current.systemVersion, forKey: "LastSeenSystemVersion")
        userDefaults.synchronize()

        setUserAgent(userAgent: userAgent)
    }

    private func cachedUserAgent() -> String? {
        guard let lastSeenSystemVersion = userDefaults.string(forKey: "LastSeenSystemVersion") else {
            return nil
        }

        if lastSeenSystemVersion != UIDevice.current.systemVersion {
            return nil
        }

        return userDefaults.string(forKey: "UserAgent")
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
    
    open static func getDesktopUserAgent() -> String {
        // TODO: check if this is suffficient. Chose this user agent instead of Firefox's method as Firefox fails to load desktop on several sites (i.e. Facebook)
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.12 (KHTML, like Gecko) Version/11.1 Safari/605.1.12"
        return String(userAgent)
    }

    private func setUserAgent(userAgent: String) {
        userDefaults.register(defaults: ["UserAgent": userAgent])
        userDefaults.synchronize()
    }
}
