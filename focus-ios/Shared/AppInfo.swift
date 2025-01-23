/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class AppInfo {
    /// Return the shared container identifier (also known as the app group) to be used with for example background
    /// http requests. It is the base bundle identifier with a "group." prefix.
    static var sharedContainerIdentifier: String {
        return "group." + AppInfo.baseBundleIdentifier
    }

    /// Return the base bundle identifier.
    ///
    /// This function is smart enough to find out if it is being called from an extension or the main application. In
    /// case of the former, it will chop off the extension identifier from the bundle since that is a suffix not part
    /// of the *base* bundle identifier.
    static var baseBundleIdentifier: String {
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
    static var contentBlockerBundleIdentifier: String {
        return baseBundleIdentifier + ".ContentBlocker"
    }

    static var productName: String {
        return Bundle.main.infoDictionary!["CFBundleName"] as! String
    }

    static var shortProductName: String {
        return isKlar ? "Klar" : "Focus"
    }

    /// Return application's ShortVersionString. Like `35`, `38.0` or `38.1.1`. Will crash if the value is missing
    /// from the Info.plist. (Which is a fatal packaging error.)
    static var shortVersion: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }

    /// Return the application's major version. It will only handle versions like `9000` or `38.1` or `38.1.1`. It
    /// will crash if the `shortVersion` is missing or malformed. (Which is a fatal packaging error.)
    static var majorVersion: Int {
        guard let dotIndex = shortVersion.firstIndex(of: ".") else {
            return Int(shortVersion)!
        }
        return Int(String(shortVersion.prefix(upTo: dotIndex)))!
    }

    static var buildNumber: String {
        return Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    }

    static var languageCode: String {
        return Bundle.main.preferredLocalizations.first!
    }

    static let isKlar: Bool = AppInfo.productName.contains("Klar")

    static var appScheme: String {
        AppInfo.isKlar ? "firefox-klar" : "firefox-focus"
    }

    static let config: AppConfig = AppInfo.isKlar ? KlarAppConfig() : FocusAppConfig()

    open class func isSimulator() -> Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] != nil
    }

    open class func isTesting() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("testMode")
    }

    static var isBetaBuild: Bool {
        return (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String)?.contains("enterprise") ?? false
    }

    open class func testRequestsReset() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("testMode")
    }

    open class func isFirstRunUIEnabled() -> Bool {
        return !ProcessInfo.processInfo.arguments.contains("disableFirstRunUI")
    }

    // The port for the internal webserver, tests can change this
    public static var webserverPort = 6571
}
