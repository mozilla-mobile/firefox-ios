/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AVFoundation
import UIKit

public class UserAgent {
    private static var defaults = NSUserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!

    public static var syncUserAgent: String {
        let appName = DeviceInfo.appName()
        return "Firefox-iOS-Sync/\(AppInfo.appVersion) (\(appName))"
    }

    public static var tokenServerClientUserAgent: String {
        let appName = DeviceInfo.appName()
        return "Firefox-iOS-Token/\(AppInfo.appVersion) (\(appName))"
    }

    public static var fxaUserAgent: String {
        let appName = DeviceInfo.appName()
        return "Firefox-iOS-FxA/\(AppInfo.appVersion) (\(appName))"
    }

    /**
     * Use this if you know that a value must have been computed before your
     * code runs, or you don't mind failure.
     */
    public static func cachedUserAgent(checkiOSVersion checkiOSVersion: Bool = true) -> String? {
        let currentiOSVersion = UIDevice.currentDevice().systemVersion
        let lastiOSVersion = defaults.stringForKey("LastDeviceSystemVersionNumber")

        if let firefoxUA = defaults.stringForKey("UserAgent") {
            if !checkiOSVersion || (lastiOSVersion == currentiOSVersion) {
                return firefoxUA
            }
        }

        return nil
    }

    /**
     * This will typically return quickly, but can require creation of a UIWebView.
     * As a result, it must be called on the UI thread.
     */
    public static func defaultUserAgent() -> String {
        assert(NSThread.currentThread().isMainThread, "This method must be called on the main thread.")

        if let firefoxUA = UserAgent.cachedUserAgent(checkiOSVersion: true) {
            return firefoxUA
        }

        let webView = UIWebView()

        let appVersion = AppInfo.appVersion
        let currentiOSVersion = UIDevice.currentDevice().systemVersion
        defaults.setObject(currentiOSVersion,forKey: "LastDeviceSystemVersionNumber")
        let userAgent = webView.stringByEvaluatingJavaScriptFromString("navigator.userAgent")!

        // Extract the WebKit version and use it as the Safari version.
        let webKitVersionRegex = try! NSRegularExpression(pattern: "AppleWebKit/([^ ]+) ", options: [])

        let match = webKitVersionRegex.firstMatchInString(userAgent, options:[],
            range: NSMakeRange(0, userAgent.characters.count))

        if match == nil {
            print("Error: Unable to determine WebKit version in UA.")
            return userAgent     // Fall back to Safari's.
        }

        let webKitVersion = (userAgent as NSString).substringWithRange(match!.rangeAtIndex(1))

        // Insert "FxiOS/<version>" before the Mobile/ section.
        let mobileRange = (userAgent as NSString).rangeOfString("Mobile/")
        if mobileRange.location == NSNotFound {
            print("Error: Unable to find Mobile section in UA.")
            return userAgent     // Fall back to Safari's.
        }

        let mutableUA = NSMutableString(string: userAgent)
        mutableUA.insertString("FxiOS/\(appVersion) ", atIndex: mobileRange.location)

        let firefoxUA = "\(mutableUA) Safari/\(webKitVersion)"

        defaults.setObject(firefoxUA, forKey: "UserAgent")

        return firefoxUA
    }

    public static func desktopUserAgent() -> String {
        let userAgent = NSMutableString(string: defaultUserAgent())

        // Spoof platform section
        let platformRegex = try! NSRegularExpression(pattern: "\\([^\\)]+\\)", options: [])
        guard let platformMatch = platformRegex.firstMatchInString(userAgent as String, options:[], range: NSMakeRange(0, userAgent.length)) else {
            print("Error: Unable to determine platform in UA.")
            return String(userAgent)
        }
        userAgent.replaceCharactersInRange(platformMatch.range, withString: "(Macintosh; Intel Mac OS X 10_11_1)")

        // Strip mobile section
        let mobileRegex = try! NSRegularExpression(pattern: " FxiOS/[^ ]+ Mobile/[^ ]+", options: [])
        guard let mobileMatch = mobileRegex.firstMatchInString(userAgent as String, options:[], range: NSMakeRange(0, userAgent.length)) else {
            print("Error: Unable to find Mobile section in UA.")
            return String(userAgent)
        }
        userAgent.replaceCharactersInRange(mobileMatch.range, withString: "")

        return String(userAgent)
    }
}
