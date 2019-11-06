/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit

open class UserAgent {
    public static let uaBitSafari = "Safari/605.1.15"
    public static let uaBitMobile = "Mobile/15E148"

    private static var defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!

    private static func clientUserAgent(prefix: String) -> String {
        return "\(prefix)/\(AppInfo.appVersion)b\(AppInfo.buildNumber) (\(DeviceInfo.deviceModel()); iPhone OS \(UIDevice.current.systemVersion)) (\(AppInfo.displayName))"
    }

    public static var syncUserAgent: String {
        return clientUserAgent(prefix: "Firefox-iOS-Sync")
    }

    public static var tokenServerClientUserAgent: String {
        return clientUserAgent(prefix: "Firefox-iOS-Token")
    }

    public static var fxaUserAgent: String {
        return clientUserAgent(prefix: "Firefox-iOS-FxA")
    }

    public static var defaultClientUserAgent: String {
        return clientUserAgent(prefix: "Firefox-iOS")
    }

    public static func defaultUserAgent() -> String {
        // As of iOS 13 using a hidden webview method does not return the correct UA on
        // iPad (it returns mobile UA). We should consider that method no longer reliable.
        if UIDevice.current.userInterfaceIdiom == .pad {
            return desktopUserAgent()
        } else {
            return mobileUserAgent()
        }
    }

    public static func isDesktop(ua: String) -> Bool {
        return ua.lowercased().contains("intel mac")
    }
    public static func desktopUserAgent() -> String {
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/\(AppInfo.appVersion) \(uaBitSafari)"
    }

    public static func mobileUserAgent() -> String {
        return "Mozilla/5.0 (\(UIDevice.current.model); CPU OS \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/\(AppInfo.appVersion)  \(uaBitMobile) \(uaBitSafari)"
    }

    public static func oppositeUserAgent() -> String {
        let isDefaultUADesktop = UserAgent.isDesktop(ua: UserAgent.defaultUserAgent())
        if isDefaultUADesktop {
            return mobileUserAgent()
        } else {
            return desktopUserAgent()
        }
    }
}
