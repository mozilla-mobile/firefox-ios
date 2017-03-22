/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum FirefoxAccountConfigurationLabel: String {
    case latestDev = "LatestDev"
    case stableDev = "StableDev"
    case stage = "Stage"
    case production = "Production"
    case chinaEdition = "ChinaEdition"

    public func toConfiguration() -> FirefoxAccountConfiguration {
        switch self {
        case .latestDev: return LatestDevFirefoxAccountConfiguration()
        case .stableDev: return StableDevFirefoxAccountConfiguration()
        case .stage: return StageFirefoxAccountConfiguration()
        case .production: return ProductionFirefoxAccountConfiguration()
        case .chinaEdition: return ChinaEditionFirefoxAccountConfiguration()
        }
    }
}

/**
 * In the URLs below, service=sync ensures that we always get the keys with signin messages,
 * and context=fx_ios_v1 opts us in to the Desktop Sync postMessage interface.
 */
public protocol FirefoxAccountConfiguration {
    init()

    var label: FirefoxAccountConfigurationLabel { get }

    /// A Firefox Account exists on a particular server.  The auth endpoint should speak the protocol documented at
    /// https://github.com/mozilla/fxa-auth-server/blob/02f88502700b0c5ef5a4768a8adf332f062ad9bf/docs/api.md
    var authEndpointURL: URL { get }

    /// The associated oauth server should speak the protocol documented at
    /// https://github.com/mozilla/fxa-oauth-server/blob/6cc91e285fc51045a365dbacb3617ef29093dbc3/docs/api.md
    var oauthEndpointURL: URL { get }

    var profileEndpointURL: URL { get }

    /// The associated content server should speak the protocol implemented (but not yet documented) at
    /// https://github.com/mozilla/fxa-content-server/blob/161bff2d2b50bac86ec46c507e597441c8575189/app/scripts/models/auth_brokers/fx-desktop.js
    var signInURL: URL { get }
    var settingsURL: URL { get }
    var forceAuthURL: URL { get }

    var sync15Configuration: Sync15Configuration { get }

    var pushConfiguration: PushConfiguration { get }
}

public struct LatestDevFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.latestDev

    public let authEndpointURL = URL(string: "https://latest.dev.lcip.org/auth/v1")!
    public let oauthEndpointURL = URL(string: "https://oauth-latest.dev.lcip.org")!
    public let profileEndpointURL = URL(string: "https://latest.dev.lcip.org/profile")!

    public let signInURL = URL(string: "https://latest.dev.lcip.org/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = URL(string: "https://latest.dev.lcip.org/settings?context=fx_ios_v1")!
    public let forceAuthURL = URL(string: "https://latest.dev.lcip.org/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = StageSync15Configuration()

    public let pushConfiguration: PushConfiguration = DeveloperPushConfiguration()
}

public struct StableDevFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.stableDev

    public let authEndpointURL = URL(string: "https://stable.dev.lcip.org/auth/v1")!
    public let oauthEndpointURL = URL(string: "https://oauth-stable.dev.lcip.org")!
    public let profileEndpointURL = URL(string: "https://stable.dev.lcip.org/profile")!

    public let signInURL = URL(string: "https://stable.dev.lcip.org/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = URL(string: "https://stable.dev.lcip.org/settings?context=fx_ios_v1")!
    public let forceAuthURL = URL(string: "https://stable.dev.lcip.org/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = StageSync15Configuration()

    public let pushConfiguration: PushConfiguration = DeveloperPushConfiguration()
}

public struct StageFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.stage

    public let authEndpointURL = URL(string: "https://api-accounts.stage.mozaws.net/v1")!
    public let oauthEndpointURL = URL(string: "https://oauth.stage.mozaws.net/v1")!
    public let profileEndpointURL = URL(string: "https://profile.stage.mozaws.net/v1")!

    public let signInURL = URL(string: "https://accounts.stage.mozaws.net/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = URL(string: "https://accounts.stage.mozaws.net/settings?context=fx_ios_v1")!
    public let forceAuthURL = URL(string: "https://accounts.stage.mozaws.net/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = StageSync15Configuration()

    public let pushConfiguration: PushConfiguration = StagePushConfiguration()
}

public struct ProductionFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.production

    public let authEndpointURL = URL(string: "https://api.accounts.firefox.com/v1")!
    public let oauthEndpointURL = URL(string: "https://oauth.accounts.firefox.com/v1")!
    public let profileEndpointURL = URL(string: "https://profile.accounts.firefox.com/v1")!

    public let signInURL = URL(string: "https://accounts.firefox.com/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = URL(string: "https://accounts.firefox.com/settings?context=fx_ios_v1")!
    public let forceAuthURL = URL(string: "https://accounts.firefox.com/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = ProductionSync15Configuration()

    public let pushConfiguration: PushConfiguration = ProductionPushConfiguration()
}

public struct ChinaEditionFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init() {
    }

    public let label = FirefoxAccountConfigurationLabel.chinaEdition

    public let authEndpointURL = URL(string: "https://api-accounts.firefox.com.cn/v1")!
    public let oauthEndpointURL = URL(string: "https://oauth.firefox.com.cn/v1")!
    public let profileEndpointURL = URL(string: "https://profile.firefox.com.cn/v1")!

    public let signInURL = URL(string: "https://accounts.firefox.com.cn/signin?service=sync&context=fx_ios_v1")!
    public let settingsURL = URL(string: "https://accounts.firefox.com.cn/settings?context=fx_ios_v1")!
    public let forceAuthURL = URL(string: "https://accounts.firefox.com.cn/force_auth?service=sync&context=fx_ios_v1")!

    public let sync15Configuration: Sync15Configuration = ChinaEditionSync15Configuration()

    public let pushConfiguration: PushConfiguration = ProductionPushConfiguration()
}

public struct ChinaEditionSync15Configuration: Sync15Configuration {
    public init() {
    }

    public let tokenServerEndpointURL = URL(string: "https://sync.firefox.com.cn/token/1.0/sync/1.5")!
}

public protocol Sync15Configuration {
    init()
    var tokenServerEndpointURL: URL { get }
}

public struct ProductionSync15Configuration: Sync15Configuration {
    public init() {
    }

    public let tokenServerEndpointURL = URL(string: "https://token.services.mozilla.com/1.0/sync/1.5")!
}

public struct StageSync15Configuration: Sync15Configuration {
    public init() {
    }

    public let tokenServerEndpointURL = URL(string: "https://token.stage.mozaws.net/1.0/sync/1.5")!
}
