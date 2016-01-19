/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class AppInfo {
    /// Return the shared container identifier (also known as the app group) to be used with for example background
    /// http requests. It is the base bundle identifier with a "group." prefix.
    public static var SharedContainerIdentifier: String {
        return "group." + AppInfo.BaseBundleIdentifier
    }

    /// Return the base bundle identifier.
    ///
    /// This function is smart enough to find out if it is being called from an extension or the main application. In
    /// case of the former, it will chop off the extension identifier from the bundle since that is a suffix not part
    /// of the *base* bundle identifier.
    public static var BaseBundleIdentifier: String {
        let bundle = NSBundle.mainBundle()
        let packageType = bundle.objectForInfoDictionaryKey("CFBundlePackageType") as! NSString
        let baseBundleIdentifier = bundle.bundleIdentifier!

        if packageType == "XPC!" {
            let components = baseBundleIdentifier.componentsSeparatedByString(".")
            return components[0..<components.count-1].joinWithSeparator(".")
        }

        return baseBundleIdentifier
    }

    /// Return the bundle identifier of the content blocker extension. We can't simply look it up from the
    /// NSBundle because this code can be called from both the main app and the extension.
    public static var ContentBlockerBundleIdentifier: String {
        return BaseBundleIdentifier + ".ContentBlocker"
    }

    public static var ProductName: String {
        return NSBundle.mainBundle().infoDictionary!["CFBundleName"] as! String
    }

    public static var LanguageCode: String {
        return NSBundle.mainBundle().preferredLocalizations.first!
    }
}