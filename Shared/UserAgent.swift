/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit

open class UserAgent {
    public static let uaBitSafari = "Safari/605.1.15"
    public static let uaBitMobile = "Mobile/15E148"

    // For iPad, we need to append this to the default UA for google.com to show correct page
    public static let uaBitGoogleIpad = "Version/13.0.3"

    private static var defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!

    private static func clientUserAgent(prefix: String) -> String {
        return UserAgentBuilder.defaultClientUserAgent().userAgent()
    }

    public static var syncUserAgent: String {
        return UserAgentBuilder.defaultClientUserAgent().modifiedUserAgent(prefix: "Firefox-iOS-Sync/")
    }

    public static var tokenServerClientUserAgent: String {
        return UserAgentBuilder.defaultClientUserAgent().modifiedUserAgent(prefix: "Firefox-iOS-Token/")
    }

    public static var fxaUserAgent: String {
        return UserAgentBuilder.defaultClientUserAgent().modifiedUserAgent(prefix: "Firefox-iOS-FxA/")
    }

    public static var defaultClientUserAgent: String {
        return UserAgentBuilder.defaultClientUserAgent().modifiedUserAgent(prefix: "Firefox-iOS/")
    }

    public static func isDesktop(ua: String) -> Bool {
        return ua.lowercased().contains("intel mac")
    }
    
    public static func desktopUserAgent() -> String {
        return UserAgentBuilder.defaultDesktopUserAgent().userAgent()
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
}

public enum UserAgentPlatform {
    case Desktop
    case Mobile
}

public struct UserAgentConstant {
    public static let mobileUserAgent = ["whatsapp.com": UserAgentBuilder.defaultMobileUserAgent().userAgent()]
    public static let desktopUserAgent = ["whatsapp.com": UserAgentBuilder.defaultDesktopUserAgent().modifiedUserAgent(extensions: "Version/\(AppInfo.appVersion) \(UserAgent.uaBitSafari)") ]
    
}

public struct UserAgentBuilder {
    fileprivate var prefix: String = ""
    fileprivate var product: String = ""
    fileprivate var systemInfo: String = ""
    fileprivate var platform: String = ""
    fileprivate var platformDetails: String = ""
    fileprivate var extensions: String = ""
    fileprivate var other: String = "" //If the useragent item we want is completely different and doesn't fall under any other items than we use the other field
    fileprivate var suffix: String = ""
    
    init(prefix: String, product: String, systemInfo: String, platform: String, platformDetails: String, extensions: String, other: String, suffix: String) {
        self.prefix = prefix
        self.product = product
        self.systemInfo = systemInfo
        self.platform = platform
        self.platformDetails = platformDetails
        self.extensions = extensions
        self.other = other
        self.suffix = suffix
    }
    
    func userAgent() -> String {
        return "\(product) \(systemInfo) \(platform) \(platformDetails) \(extensions)"
    }
    
    func modifiedUserAgent(prefix: String? = nil, product: String? = nil, systemInfo: String? = nil, platform: String? = nil, platformDetails: String? = nil, extensions: String? = nil, other: String? = nil, suffix: String? = nil) -> String {
        return "\(prefix ?? self.prefix) \(product ?? self.product) \(systemInfo ?? self.systemInfo) \(platform ?? self.platform) \(platformDetails ?? self.platformDetails) \(extensions ?? self.extensions)"
    }
    
    public static func defaultClientUserAgent() -> UserAgentBuilder {
        return UserAgentBuilder(prefix: "Firefox-iOS/", product: "", systemInfo: "", platform: "", platformDetails: "", extensions: "", other: "\(AppInfo.appVersion)b\(AppInfo.buildNumber) (\(DeviceInfo.deviceModel()); iPhone OS \(UIDevice.current.systemVersion)) (\(AppInfo.displayName)", suffix: "")
    }
    
    public static func defaultMobileUserAgent() -> UserAgentBuilder {
        return UserAgentBuilder(prefix: "", product: "Mozilla/5.0", systemInfo: "(\(UIDevice.current.model); CPU OS \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X)", platform: "AppleWebKit/605.1.15", platformDetails: "(KHTML, like Gecko)", extensions: "FxiOS/\(AppInfo.appVersion)  \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari)", other: "", suffix: "")
    }
    
    public static func defaultDesktopUserAgent() -> UserAgentBuilder {
        return UserAgentBuilder(prefix: "", product: "Mozilla/5.0", systemInfo: "(Macintosh; Intel Mac OS X 10.15)", platform: "AppleWebKit/605.1.15", platformDetails: "(KHTML, like Gecko)", extensions: "FxiOS/\(AppInfo.appVersion) \(UserAgent.uaBitSafari)", other: "", suffix: "")
    }
}

extension UserAgent {
    
    public static func getUserAgent(domain: String, platform: UserAgentPlatform) -> String {
        switch platform {
        case .Desktop:
            if let customUA = UserAgentConstant.desktopUserAgent[domain] {
                return customUA
            } else {
                return desktopUserAgent()
            }
        case .Mobile:
            if let customUA = UserAgentConstant.mobileUserAgent[domain] {
                return customUA
            } else {
                return mobileUserAgent()
            }
        }
    }
    
    public static func getUserAgent(domain: String) -> String {
        // As of iOS 13 using a hidden webview method does not return the correct UA on
        // iPad (it returns mobile UA). We should consider that method no longer reliable.
        if UIDevice.current.userInterfaceIdiom == .pad {
            return getUserAgent(domain: domain, platform: .Desktop)
        } else {
            return getUserAgent(domain: domain, platform: .Mobile)
        }
    }
}
