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
        userDefaults.set(AppInfo.shortVersion, forKey: "LastFocusVersionNumber")
        userDefaults.set(AppInfo.buildNumber, forKey: "LastFocusBuildNumber")
        userDefaults.set(UIDevice.current.systemVersion, forKey: "LastDeviceSystemVersionNumber")

        setUserAgent(userAgent: userAgent)
    }

    private func cachedUserAgent() -> String? {
        let currentiOSVersion = UIDevice.current.systemVersion
        let lastiOSVersion = userDefaults.string(forKey: "LastDeviceSystemVersionNumber")
        let currentFocusVersion = AppInfo.shortVersion
        let lastFocusVersion = userDefaults.string(forKey: "LastFocusVersionNumber")
        let currentFocusBuild = AppInfo.buildNumber
        let lastFocusBuild = userDefaults.string(forKey: "LastFocusBuildNumber")

        if let focusUA = userDefaults.string(forKey: "UserAgent") {
            if (lastiOSVersion == currentiOSVersion
                && lastFocusVersion == currentFocusVersion
                && lastFocusBuild == currentFocusBuild) {
                return focusUA
            }
        }
        return nil
    }

    private static func generateUserAgent() -> String? {
        let webView = UIWebView()

        let userAgent = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent")!

        // Extract the WebKit version and use it as the Safari version.
        let webKitVersionRegex = try! NSRegularExpression(pattern: "AppleWebKit/([^ ]+) ", options: [])

        let match = webKitVersionRegex.firstMatch(in: userAgent, options: [],
                                                  range: NSRange(location: 0, length: userAgent.count))

        if match == nil {
            print("Error: Unable to determine WebKit version in UA.")
            return userAgent     // Fall back to Safari's.
        }

        let webKitVersion = (userAgent as NSString).substring(with: match!.range(at: 1))

        // Insert version before the Mobile/ section.
        let mobileRange = (userAgent as NSString).range(of: "Mobile/")
        if mobileRange.location == NSNotFound {
            print("Error: Unable to find Mobile section in UA.")
            return userAgent     // Fall back to Safari's.
        }

        let mutableUA = NSMutableString(string: userAgent)
        mutableUA.insert("FocusiOS/\(AppInfo.shortVersion) ", at: mobileRange.location)

        let focusUA = "\(mutableUA) Safari/\(webKitVersion)"

        return focusUA
    }
    
    public static func getDesktopUserAgent() -> String {
        // TODO: check if this is suffficient. Chose this user agent instead of Firefox's method as Firefox fails to load desktop on several sites (i.e. Facebook)
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.12 (KHTML, like Gecko) Version/11.1 Safari/605.1.12"
        return String(userAgent)
    }

    private func setUserAgent(userAgent: String) {
        userDefaults.register(defaults: ["UserAgent": userAgent])
        userDefaults.synchronize()
    }
}
