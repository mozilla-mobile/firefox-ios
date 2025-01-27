// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

extension AppInfo {
    public static var displayName: String {
        guard let displayName = applicationBundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String else {
            fatalError("CFBundleDisplayName not found in info.plist")
        }
        return displayName
    }

    public static var majorAppVersion: String {
        return appVersion.components(separatedBy: ".").first!
    }

    /// The port for the internal webserver, tests can change this
    /// Please be aware that we needed to migrate this webserverPort in WebEngine.WKEngineInfo
    /// due to Shared target issues in #17721. This webserverPort needs to be deleted with
    /// FXIOS-7960 once the WebEngine package is integrated in Firefox iOS
    public static var webserverPort = 6571

    /// Return the keychain access group.
    public static func keychainAccessGroupWithPrefix(_ prefix: String) -> String {
        var bundleIdentifier = baseBundleIdentifier
        if bundleIdentifier == "org.mozilla.ios.FennecEnterprise" {
            // Bug 1373726 - Base bundle identifier incorrectly generated for Nightly builds
            // This can be removed when we are able to fix the app group in the developer portal
            bundleIdentifier = "org.mozilla.ios.Fennec.enterprise"
        }
        return prefix + "." + bundleIdentifier
    }

    // Return the MozWhatsNewTopic key from the Info.plist
    public static var whatsNewTopic: String? {
        // By default we don't want to add dot version to what's new section. Set
        // this to true if you'd like to add dot version for whats new article.
        let shouldAddDotVersion = false
        let appVersionSplit = AppInfo.appVersion.components(separatedBy: ".")
        let majorAppVersion = appVersionSplit[0]
        var dotVersion = ""
        if appVersionSplit.count > 1, appVersionSplit[0] != "0" { dotVersion = appVersionSplit[1] }
        let topic = "whats-new-ios-\(majorAppVersion)\(shouldAddDotVersion ? dotVersion : "")"
        return topic
    }

    public static let debugPrefIsChinaEdition = "debugPrefIsChinaEdition"

    public static var isChinaEdition: Bool = {
        if UserDefaults.standard.bool(forKey: AppInfo.debugPrefIsChinaEdition) {
            return true
        }
        return Locale.current.identifier == "zh_CN"
    }()

    // The App Store page identifier for the Firefox iOS application
    public static var appStoreId = "id989804926"

    /// Return the shared container identifier (also known as the app group) to be used with for example background
    /// http requests. It is the base bundle identifier with a "group." prefix.
    public static var sharedContainerIdentifier: String {
        var bundleIdentifier = baseBundleIdentifier
        if bundleIdentifier == "org.mozilla.ios.FennecEnterprise" {
            // Bug 1373726 - Base bundle identifier incorrectly generated for Nightly builds
            // This can be removed when we are able to fix the app group in the developer portal
            bundleIdentifier = "org.mozilla.ios.Fennec.enterprise"
        }
        return "group." + bundleIdentifier
    }
}
