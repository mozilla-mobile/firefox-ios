// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import UIKit

open class UserAgent {
    public static let uaBitSafari = "Safari/604.1"
    public static let uaBitMobile = "Mobile/15E148"
    public static let uaBitFx = "FxiOS/\(AppInfo.appVersion)"
    public static let product = "Mozilla/5.0"
    public static let platform = "AppleWebKit/605.1.15"
    public static let platformDetails = "(KHTML, like Gecko)"

    // FIXME: FXIOS-13197 UserDefaults is not thread safe
    nonisolated(unsafe) private static let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!

    private static func clientUserAgent(prefix: String) -> String {
        let versionStr: String
        if AppInfo.buildNumber != "1" {
            versionStr = "\(AppInfo.appVersion)b\(AppInfo.buildNumber)"
        } else {
            versionStr = "dev"
        }
        return "\(prefix)/\(versionStr) (\(DeviceInfo.deviceModel()); iPhone OS \(UIDeviceDetails.systemVersion)) (\(AppInfo.displayName))"
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

    public static func isDesktop(ua: String) -> Bool {
        return ua.lowercased().contains("intel mac")
    }

    public static func desktopUserAgent() -> String {
        // swiftlint:disable line_length
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15"
        // swiftlint:enable line_length
    }

    public static func mobileUserAgent() -> String {
        return UserAgentBuilder.defaultMobileUserAgent().userAgent()
    }

    public static func oppositeUserAgent(domain: String) -> String {
        let isDefaultUADesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent(domain: domain))
        if isDefaultUADesktop {
            return UserAgent.getUserAgent(domain: domain, platform: .Mobile)
        } else {
            return UserAgent.getUserAgent(domain: domain, platform: .Desktop)
        }
    }

    public static func getUserAgent(domain: String, platform: UserAgentPlatform) -> String {
        switch platform {
        case .Desktop:
            guard let customUA = CustomUserAgentConstant.customDesktopUAForDomain[domain] else {
                return desktopUserAgent()
            }
            return customUA
        case .Mobile:
            guard let customUA = CustomUserAgentConstant.customMobileUAForDomain[domain] else {
                return mobileUserAgent()
            }
            return customUA
        }
    }

    public static func getUserAgent(domain: String = "") -> String {
        // As of iOS 13 using a hidden webview method does not return the correct UA on
        // iPad (it returns mobile UA). We should consider that method no longer reliable.
        if UIDeviceDetails.userInterfaceIdiom == .pad {
            return getUserAgent(domain: domain, platform: .Desktop)
        } else {
            return getUserAgent(domain: domain, platform: .Mobile)
        }
    }
}

public enum UserAgentPlatform {
    case Desktop
    case Mobile
}

struct CustomUserAgentConstant {
    private static let defaultMobileUA = UserAgentBuilder.defaultMobileUserAgent().userAgent()
    private static let safariMobileUA = UserAgentBuilder.defaultMobileUserAgent().clone(extensions: "Version/18.6 \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari)")

    static let customMobileUAForDomain = [
        // TODO: FXIOS-13391 [webcompat] "connection error" only on FxiOS/* UA (bug 1983983)
        "tver.jp": safariMobileUA,
        // TODO: FXIOS-13096 [webcompat] UA version parsed as "Safari 0" (webcompat #170304)
        "epic.com": safariMobileUA,
        "athenahealth.com": safariMobileUA,
        "ehealthontario.ca": safariMobileUA
    ]

    static let customDesktopUAForDomain = [
        "paypal.com": defaultMobileUA,
        "firefox.com": defaultMobileUA
    ]
}

public struct UserAgentBuilder {
    // User agent components
    fileprivate var product = ""
    fileprivate var systemInfo = ""
    fileprivate var platform = ""
    fileprivate var platformDetails = ""
    fileprivate var extensions = ""

    init(
        product: String,
        systemInfo: String,
        platform: String,
        platformDetails: String,
        extensions: String
    ) {
        self.product = product
        self.systemInfo = systemInfo
        self.platform = platform
        self.platformDetails = platformDetails
        self.extensions = extensions
    }

    public func userAgent() -> String {
        let userAgentItems = [product, systemInfo, platform, platformDetails, extensions]
        return removeEmptyComponentsAndJoin(uaItems: userAgentItems)
    }

    public func clone(
        product: String? = nil,
        systemInfo: String? = nil,
        platform: String? = nil,
        platformDetails: String? = nil,
        extensions: String? = nil
    ) -> String {
        let userAgentItems = [
            product ?? self.product,
            systemInfo ?? self.systemInfo,
            platform ?? self.platform,
            platformDetails ?? self.platformDetails,
            extensions ?? self.extensions
        ]
        return removeEmptyComponentsAndJoin(uaItems: userAgentItems)
    }

    /// Helper method to remove the empty components from user agent string that contain
    /// only whitespaces or are just empty
    private func removeEmptyComponentsAndJoin(uaItems: [String]) -> String {
        return uaItems.filter { !$0.isEmptyOrWhitespace() }.joined(separator: " ")
    }

    public static func defaultMobileUserAgent() -> UserAgentBuilder {
        return UserAgentBuilder(
            product: UserAgent.product,
            systemInfo: "(\(UIDeviceDetails.model); CPU iPhone OS \(UIDeviceDetails.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X)",
            platform: UserAgent.platform,
            platformDetails: UserAgent.platformDetails,
            extensions: "FxiOS/\(AppInfo.appVersion)  \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari)")
    }

    public static func defaultDesktopUserAgent() -> UserAgentBuilder {
        return UserAgentBuilder(
            product: UserAgent.product,
            systemInfo: "(Macintosh; Intel Mac OS X 10_15_7)",
            platform: UserAgent.platform,
            platformDetails: UserAgent.platformDetails,
            extensions: "Version/18.6 Safari/605.1.15")
    }
}
