/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class AppInfo {
    /// Return the shared container identifier (also known as the app group) to be used with for example background
    /// http requests. It is the base bundle identifier with a "group." prefix.
    static var SharedContainerIdentifier: String {
        return "group." + AppInfo.BaseBundleIdentifier
    }

    /// Return the base bundle identifier.
    ///
    /// This function is smart enough to find out if it is being called from an extension or the main application. In
    /// case of the former, it will chop off the extension identifier from the bundle since that is a suffix not part
    /// of the *base* bundle identifier.
    static var BaseBundleIdentifier: String {
        assert(Thread.isMainThread)

        let bundle = Bundle.main
        let packageType = bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as! NSString
        let baseBundleIdentifier = bundle.bundleIdentifier!

        if packageType == "XPC!" {
            let components = baseBundleIdentifier.components(separatedBy: ".")
            return components[0..<components.count-1].joined(separator: ".")
        }

        return baseBundleIdentifier
    }

    /// Return the bundle identifier of the content blocker extension. We can't simply look it up from the
    /// NSBundle because this code can be called from both the main app and the extension.
    static var ContentBlockerBundleIdentifier: String {
        return BaseBundleIdentifier + ".ContentBlocker"
    }

    static var ProductName: String {
        assert(Thread.isMainThread)

        return Bundle.main.infoDictionary!["CFBundleName"] as! String
    }

    static var ShortVersion: String {
        assert(Thread.isMainThread)

        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }

    static var LanguageCode: String {
        assert(Thread.isMainThread)

        return Bundle.main.preferredLocalizations.first!
    }

    static var isFocus: Bool {
        return AppInfo.ProductName.contains("Focus")
    }
}
