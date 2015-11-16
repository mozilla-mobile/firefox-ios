/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum FirefoxAccountConfigurationLabel: String {
    case LatestDev = "LatestDev"
    case StableDev = "StableDev"
    case Production = "Production"
    case ChinaEdition = "ChinaEdition"

    public func toConfiguration() -> FirefoxAccountConfiguration {
        switch self {
        case LatestDev: return LatestDevFirefoxAccountConfiguration()
        case StableDev: return StableDevFirefoxAccountConfiguration()
        case Production: return ProductionFirefoxAccountConfiguration()
        case ChinaEdition: return ChinaEditionFirefoxAccountConfiguration()
        }
    }
}

/**
 * In the URLs below, service=sync ensures that we always get the keys with signin messages,
 * and context=fx_ios_v1 opts us in to the Desktop Sync postMessage interface.
 *
 * For the moment we add exclude_signup as a parameter to limit the UI; see Bug 1190097.
 */
public protocol FirefoxAccountConfiguration {
    init()

    var label: FirefoxAccountConfigurationLabel { get }

    /// A Firefox Account exists on a particular server.  The auth endpoint should speak the protocol documented at
    /// https://github.com/mozilla/fxa-auth-server/blob/02f88502700b0c5ef5a4768a8adf332f062ad9bf/docs/api.md
    var authEndpointURL: NSURL { get }

    /// The associated oauth server should speak the protocol documented at
    /// https://github.com/mozilla/fxa-oauth-server/blob/6cc91e285fc51045a365dbacb3617ef29093dbc3/docs/api.md
    var oauthEndpointURL: NSURL { get }

    var profileEndpointURL: NSURL { get }

    /// The associated content server should speak the protocol implemented (but not yet documented) at
    /// https://github.com/mozilla/fxa-content-server/blob/161bff2d2b50bac86ec46c507e597441c8575189/app/scripts/models/auth_brokers/fx-desktop.js
    var signInURL: NSURL { get }
    var settingsURL: NSURL { get }
    var forceAuthURL: NSURL { get }

    var sync15Configuration: Sync15Configuration { get }
}

public struct LatestDevFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.LatestDev

    public let authEndpointURL = NSURL(string: "https://latest.dev.lcip.org/auth/v1")!
    public let oauthEndpointURL = NSURL(string: "https://oauth-latest.dev.lcip.org")!
    public let profileEndpointURL = NSURL(string: "https://latest.dev.lcip.org/profile")!

    public let signInURL = NSURL(string: "https://latest.dev.lcip.org/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = NSURL(string: "https://latest.dev.lcip.org/settings?context=fx_ios_v1")!
    public let forceAuthURL = NSURL(string: "https://latest.dev.lcip.org/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = StageSync15Configuration()
}

public struct StableDevFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.StableDev

    public let authEndpointURL = NSURL(string: "https://stable.dev.lcip.org/auth/v1")!
    public let oauthEndpointURL = NSURL(string: "https://oauth-stable.dev.lcip.org")!
    public let profileEndpointURL = NSURL(string: "https://stable.dev.lcip.org/profile")!

    public let signInURL = NSURL(string: "https://stable.dev.lcip.org/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = NSURL(string: "https://stable.dev.lcip.org/settings?context=fx_ios_v1")!
    public let forceAuthURL = NSURL(string: "https://stable.dev.lcip.org/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = StageSync15Configuration()
}

public struct ProductionFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.Production

    public let authEndpointURL = NSURL(string: "https://api.accounts.firefox.com/v1")!
    public let oauthEndpointURL = NSURL(string: "https://oauth.accounts.firefox.com/v1")!
    public let profileEndpointURL = NSURL(string: "https://profile.accounts.firefox.com/v1")!

    public let signInURL = NSURL(string: "https://accounts.firefox.com/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = NSURL(string: "https://accounts.firefox.com/settings?context=fx_ios_v1")!
    public let forceAuthURL = NSURL(string: "https://accounts.firefox.com/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = ProductionSync15Configuration()
}

public struct ChinaEditionFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.ChinaEdition

    public let authEndpointURL = NSURL(string: "https://api-accounts.firefox.com.cn/v1")!
    public let oauthEndpointURL = NSURL(string: "https://oauth.firefox.com.cn/v1")!
    public let profileEndpointURL = NSURL(string: "https://profile.firefox.com.cn/v1")!

    public let signInURL = NSURL(string: "https://accounts.firefox.com.cn/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = NSURL(string: "https://accounts.firefox.com.cn/settings?context=fx_ios_v1")!
    public let forceAuthURL = NSURL(string: "https://accounts.firefox.com.cn/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = ChinaEditionSync15Configuration()
}

public struct ChinaEditionSync15Configuration: Sync15Configuration {
    public init() {
    }

    public let tokenServerEndpointURL = NSURL(string: "https://sync.firefox.com.cn/token/1.0/sync/1.5")!
}

public protocol Sync15Configuration {
    init()
    var tokenServerEndpointURL: NSURL { get }
}

public struct ProductionSync15Configuration: Sync15Configuration {
    public init() {
    }

    public let tokenServerEndpointURL = NSURL(string: "https://token.services.mozilla.com/1.0/sync/1.5")!
}

public struct StageSync15Configuration: Sync15Configuration {
    public init() {
    }

    public let tokenServerEndpointURL = NSURL(string: "https://token.stage.mozaws.net/1.0/sync/1.5")!
}
