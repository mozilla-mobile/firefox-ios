/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AVFoundation
import UIKit

public class UserAgent {
    public static func defaultUserAgent() -> String {
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        
        let currentiOSVersion = UIDevice.currentDevice().systemVersion
        let lastiOSVersion = NSUserDefaults.standardUserDefaults().stringForKey("LastDeviceSystemVersionNumber")
        var firefoxUA = NSUserDefaults.standardUserDefaults().stringForKey("UserAgent")
        if firefoxUA == nil
            || lastiOSVersion != currentiOSVersion {
                
                let webView = UIWebView()
                
                NSUserDefaults.standardUserDefaults().setObject(currentiOSVersion,forKey: "LastDeviceSystemVersionNumber")
                let userAgent = webView.stringByEvaluatingJavaScriptFromString("navigator.userAgent")!
                
                // Extract the WebKit version and use it as the Safari version.
                let webKitVersionRegex = NSRegularExpression(pattern: "AppleWebKit/([^ ]+) ", options: nil, error: nil)!
                let match = webKitVersionRegex.firstMatchInString(userAgent, options: nil, range: NSRange(location: 0, length: count(userAgent)))
                if match == nil {
                    println("Error: Unable to determine WebKit version")
                    return ""
                }
                let webKitVersion = (userAgent as NSString).substringWithRange(match!.rangeAtIndex(1))
                
                // Insert "FxiOS/<version>" before the Mobile/ section.
                let mobileRange = (userAgent as NSString).rangeOfString("Mobile/")
                if mobileRange.location == NSNotFound {
                    println("Error: Unable to find Mobile section")
                    return ""
                }
                
                let mutableUA = NSMutableString(string: userAgent)
                mutableUA.insertString("FxiOS/\(appVersion) ", atIndex: mobileRange.location)
                firefoxUA = "\(mutableUA) Safari/\(webKitVersion)"
                
                NSUserDefaults.standardUserDefaults().setObject(firefoxUA, forKey: "UserAgent")
        }
        
        return firefoxUA!
    }
}
