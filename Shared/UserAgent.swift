/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AVFoundation
import UIKit

open class UserAgent {
    private static var defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!

    private static func clientUserAgent(prefix: String) -> String {
        return "\(prefix)/\(AppInfo.appVersion)b\(AppInfo.buildNumber) " +
               "(\(DeviceInfo.deviceModel()); iPhone OS \(UIDevice.current.systemVersion)) (\(DeviceInfo.appName()))"
    }

    open static var syncUserAgent: String {
        return clientUserAgent(prefix: "Firefox-iOS-Sync")
    }

    open static var tokenServerClientUserAgent: String {
        return clientUserAgent(prefix: "Firefox-iOS-Token")
    }

    open static var fxaUserAgent: String {
        return clientUserAgent(prefix: "Firefox-iOS-FxA")
    }

    /**
     * Use this if you know that a value must have been computed before your
     * code runs, or you don't mind failure.
     */
    open static func cachedUserAgent(checkiOSVersion: Bool = true,
                                     checkFirefoxVersion: Bool = true,
                                     checkFirefoxBuildNumber: Bool = true) -> String? {
        let currentiOSVersion = UIDevice.current.systemVersion
        let lastiOSVersion = defaults.string(forKey: "LastDeviceSystemVersionNumber")

        let currentFirefoxBuildNumber = AppInfo.buildNumber
        let currentFirefoxVersion = AppInfo.appVersion
        let lastFirefoxVersion = defaults.string(forKey: "LastFirefoxVersionNumber")
        let lastFirefoxBuildNumber = defaults.string(forKey: "LastFirefoxBuildNumber")
        
        if let firefoxUA = defaults.string(forKey: "UserAgent") {
            if (!checkiOSVersion || (lastiOSVersion == currentiOSVersion))
                && (!checkFirefoxVersion || (lastFirefoxVersion == currentFirefoxVersion)
                && (!checkFirefoxBuildNumber || (lastFirefoxBuildNumber == currentFirefoxBuildNumber))) {
                return firefoxUA
            }
        }

        return nil
    }

    /**
     * This will typically return quickly, but can require creation of a UIWebView.
     * As a result, it must be called on the UI thread.
     */
    open static func defaultUserAgent() -> String {
        assert(Thread.current.isMainThread, "This method must be called on the main thread.")

        if let firefoxUA = UserAgent.cachedUserAgent(checkiOSVersion: true) {
            return firefoxUA
        }

        let webView = UIWebView()

        let appVersion = AppInfo.appVersion
        let buildNumber = AppInfo.buildNumber
        let currentiOSVersion = UIDevice.current.systemVersion
        defaults.set(currentiOSVersion, forKey: "LastDeviceSystemVersionNumber")
        defaults.set(appVersion, forKey: "LastFirefoxVersionNumber")
        defaults.set(buildNumber, forKey: "LastFirefoxBuildNumber")

        let userAgent = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent")!

        // Extract the WebKit version and use it as the Safari version.
        let webKitVersionRegex = try! NSRegularExpression(pattern: "AppleWebKit/([^ ]+) ", options: [])

        let match = webKitVersionRegex.firstMatch(in: userAgent, options:[],
            range: NSRange(location: 0, length: userAgent.characters.count))

        if match == nil {
            print("Error: Unable to determine WebKit version in UA.")
            return userAgent     // Fall back to Safari's.
        }

        let webKitVersion = (userAgent as NSString).substring(with: match!.rangeAt(1))

        // Insert "FxiOS/<version>" before the Mobile/ section.
        let mobileRange = (userAgent as NSString).range(of: "Mobile/")
        if mobileRange.location == NSNotFound {
            print("Error: Unable to find Mobile section in UA.")
            return userAgent     // Fall back to Safari's.
        }

        let mutableUA = NSMutableString(string: userAgent)
        mutableUA.insert("FxiOS/\(appVersion)b\(AppInfo.buildNumber) ", at: mobileRange.location)

        let firefoxUA = "\(mutableUA) Safari/\(webKitVersion)"

        defaults.set(firefoxUA, forKey: "UserAgent")

        return firefoxUA
    }

    open static func desktopUserAgent() -> String {
        let userAgent = NSMutableString(string: defaultUserAgent())

        // Spoof platform section
        let platformRegex = try! NSRegularExpression(pattern: "\\([^\\)]+\\)", options: [])
        guard let platformMatch = platformRegex.firstMatch(in: userAgent as String, options:[], range: NSRange(location: 0, length: userAgent.length)) else {
            print("Error: Unable to determine platform in UA.")
            return String(userAgent)
        }
        userAgent.replaceCharacters(in: platformMatch.range, with: "(Macintosh; Intel Mac OS X 10_11_1)")

        // Strip mobile section
        let mobileRegex = try! NSRegularExpression(pattern: " FxiOS/[^ ]+ Mobile/[^ ]+", options: [])
        
        guard let mobileMatch = mobileRegex.firstMatch(in: userAgent as String, options:[], range: NSRange(location: 0, length: userAgent.length)) else {
            print("Error: Unable to find Mobile section in UA.")
            return String(userAgent)
        }
        userAgent.replaceCharacters(in: mobileMatch.range, with: "")

        return String(userAgent)
    }
}
