// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

open class AppInfo {
    /// Return the main application bundle. If this is called from an extension, the containing app bundle is returned.
    public static var applicationBundle: Bundle {
        let bundle = Bundle.main
        switch bundle.bundleURL.pathExtension {
        case "app":
            return bundle
        case "appex":
            // .../Client.app/PlugIns/SendTo.appex
            return Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())!
        default:
            fatalError("Unable to get application Bundle (Bundle.main.bundlePath=\(bundle.bundlePath))")
        }
    }

    public static var bundleIdentifier: String {
        guard let bundleIdentifier = applicationBundle.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String else {
            fatalError("CFBundleIdentifier not found in info.plist")
        }
        return bundleIdentifier
    }

    public static var appVersion: String {
        guard let appVersion = applicationBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            fatalError("CFBundleShortVersionString not found in info.plist")
        }
        return appVersion
    }

    public static var buildNumber: String {
        guard let buildNumber = applicationBundle.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as? String else {
            fatalError("kCFBundleVersionKey not found in info.plist")
        }
        return buildNumber
    }

    /// Return the base bundle identifier.
    ///
    /// This function is smart enough to find out if it is being called from an extension or the main application. In
    /// case of the former, it will chop off the extension identifier from the bundle since that is a suffix not part
    /// of the *base* bundle identifier.
    public static var baseBundleIdentifier: String {
        let bundle = Bundle.main
        guard let packageType = bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as? String else {
            fatalError("CFBundlePackageType not found in info.plist")
        }
        let baseBundleIdentifier = bundle.bundleIdentifier!
        if packageType == "XPC!" {
            let components = baseBundleIdentifier.components(separatedBy: ".")
            return components[0..<components.count-1].joined(separator: ".")
        }
        return baseBundleIdentifier
    }
}
