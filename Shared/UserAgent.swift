/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AVFoundation
import UIKit

public class UserAgent {
    public static func defaultUserAgent() -> String {
        let defaults = NSUserDefaults.standardUserDefaults()

        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let currentiOSVersion = UIDevice.currentDevice().systemVersion
        let lastiOSVersion = defaults.stringForKey("LastDeviceSystemVersionNumber")

        if let firefoxUA = defaults.stringForKey("UserAgent") {
            if lastiOSVersion == currentiOSVersion {
                return firefoxUA
            }
        }

        let webView = UIWebView()

        defaults.setObject(currentiOSVersion,forKey: "LastDeviceSystemVersionNumber")
        let userAgent = webView.stringByEvaluatingJavaScriptFromString("navigator.userAgent")!

        // Extract the WebKit version and use it as the Safari version.
        let webKitVersionRegex = NSRegularExpression(pattern: "AppleWebKit/([^ ]+) ", options: nil, error: nil)!
        let match = webKitVersionRegex.firstMatchInString(userAgent, options: nil, range: NSRange(location: 0, length: count(userAgent)))

        if match == nil {
            println("Error: Unable to determine WebKit version in UA.")
            return userAgent     // Fall back to Safari's.
        }

        let webKitVersion = (userAgent as NSString).substringWithRange(match!.rangeAtIndex(1))

        // Insert "FxiOS/<version>" before the Mobile/ section.
        let mobileRange = (userAgent as NSString).rangeOfString("Mobile/")
        if mobileRange.location == NSNotFound {
            println("Error: Unable to find Mobile section in UA.")
            return userAgent     // Fall back to Safari's.
        }

        let mutableUA = NSMutableString(string: userAgent)
        mutableUA.insertString("FxiOS/\(appVersion) ", atIndex: mobileRange.location)

        let firefoxUA = "\(mutableUA) Safari/\(webKitVersion)"

        defaults.setObject(firefoxUA, forKey: "UserAgent")
        defaults.registerDefaults(["UserAgent": firefoxUA])      // Not strictly necessary, but v1 isn't the time to change things.

        return firefoxUA
    }
}
