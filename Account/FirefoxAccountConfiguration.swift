/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Production Server URLs
// From https://accounts.firefox.com/.well-known/fxa-client-configuration
private let ProductionAuthEndpointURL = URL(string: "https://api.accounts.firefox.com/v1")!
private let ProductionOAuthEndpointURL = URL(string: "https://oauth.accounts.firefox.com/v1")!
private let ProductionProfileEndpointURL = URL(string: "https://profile.accounts.firefox.com/v1")!
private let ProductionTokenServerEndpointURL = URL(string: "https://token.services.mozilla.com/1.0/sync/1.5")!
private let ProductionSignInURL = URL(string: "https://accounts.firefox.com/signin?service=sync&context=fx_ios_v1")!
private let ProductionSettingsURL = URL(string: "https://accounts.firefox.com/settings?context=fx_ios_v1")!
private let ProductionForceAuthURL = URL(string: "https://accounts.firefox.com/force_auth?service=sync&context=fx_ios_v1")!

// China Server URLs
// From https://accounts.firefox.com.cn/.well-known/fxa-client-configuration
private let ChinaAuthEndpointURL = URL(string: "https://api-accounts.firefox.com.cn/v1")!
private let ChinaOAuthEndpointURL = URL(string: "https://oauth.firefox.com.cn/v1")!
private let ChinaProfileEndpointURL = URL(string: "https://profile.firefox.com.cn/v1")!
private let ChinaTokenServerEndpointURL = URL(string: "https://sync.firefox.com.cn/token/1.0/sync/1.5")!
private let ChinaSignInURL = URL(string: "https://accounts.firefox.com.cn/signin?service=sync&context=fx_ios_v1")!
private let ChinaSettingsURL = URL(string: "https://accounts.firefox.com.cn/settings?context=fx_ios_v1")!
private let ChinaForceAuthURL = URL(string: "https://accounts.firefox.com.cn/force_auth?service=sync&context=fx_ios_v1")!

// Stage Server URLs
// From https://accounts.stage.mozaws.net/.well-known/fxa-client-configuration
private let StageAuthEndpointURL = URL(string: "https://api-accounts.stage.mozaws.net/v1")!
private let StageOAuthEndpointURL = URL(string: "https://oauth.stage.mozaws.net/v1")!
private let StageProfileEndpointURL = URL(string: "https://profile.stage.mozaws.net/v1")!
private let StageTokenServerEndpointURL = URL(string: "https://token.stage.mozaws.net/1.0/sync/1.5")!
private let StageSignInURL = URL(string: "https://accounts.stage.mozaws.net/signin?service=sync&context=fx_ios_v1")!
private let StageSettingsURL = URL(string: "https://accounts.stage.mozaws.net/settings?context=fx_ios_v1")!
private let StageForceAuthURL = URL(string: "https://accounts.stage.mozaws.net/force_auth?service=sync&context=fx_ios_v1")!

// Latest Dev Server URLs
// From https://latest.dev.lcip.org/.well-known/fxa-client-configuration
private let LatestDevAuthEndpointURL = URL(string: "https://latest.dev.lcip.org/auth/v1")!
private let LatestDevOAuthEndpointURL = URL(string: "https://oauth-latest.dev.lcip.org")!
private let LatestDevProfileEndpointURL = URL(string: "https://latest.dev.lcip.org/profile")!
private let LatestDevSignInURL = URL(string: "https://latest.dev.lcip.org/signin?service=sync&context=fx_ios_v1")!
private let LatestDevSettingsURL = URL(string: "https://latest.dev.lcip.org/settings?context=fx_ios_v1")!
private let LatestDevForceAuthURL = URL(string: "https://latest.dev.lcip.org/force_auth?service=sync&context=fx_ios_v1")!

// Stable Dev Server URLs
// From https://stable.dev.lcip.org/.well-known/fxa-client-configuration
public let StableDevAuthEndpointURL = URL(string: "https://stable.dev.lcip.org/auth/v1")!
public let StableDevOAuthEndpointURL = URL(string: "https://oauth-stable.dev.lcip.org")!
public let StableDevProfileEndpointURL = URL(string: "https://stable.dev.lcip.org/profile")!
public let StableDevSignInURL = URL(string: "https://stable.dev.lcip.org/signin?service=sync&context=fx_ios_v1")!
public let StableDevSettingsURL = URL(string: "https://stable.dev.lcip.org/settings?context=fx_ios_v1")!
public let StableDevForceAuthURL = URL(string: "https://stable.dev.lcip.org/force_auth?service=sync&context=fx_ios_v1")!

public enum FirefoxAccountConfigurationLabel: String {
    case production = "Production"
    case chinaEdition = "ChinaEdition"
    case stage = "Stage"
    case latestDev = "LatestDev"
    case stableDev = "StableDev"
    case custom = "Custom"

    public func toConfiguration(prefs: Prefs) -> FirefoxAccountConfiguration {
        switch self {
            case .production: return ProductionFirefoxAccountConfiguration(prefs: prefs)
            case .chinaEdition: return ChinaEditionFirefoxAccountConfiguration(prefs: prefs)
            case .stage: return StageFirefoxAccountConfiguration(prefs: prefs)
            case .latestDev: return LatestDevFirefoxAccountConfiguration(prefs: prefs)
            case .stableDev: return StableDevFirefoxAccountConfiguration(prefs: prefs)
            case .custom: return CustomFirefoxAccountConfiguration(prefs: prefs)
        }
    }
}

/**
 * In the URLs below, service=sync ensures that we always get the keys with signin messages,
 * and context=fx_ios_v1 opts us in to the Desktop Sync postMessage interface.
 */
public protocol FirefoxAccountConfiguration {
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

    var prefs: Prefs { get }

    init(prefs: Prefs)
}

public protocol Sync15Configuration {
    var tokenServerEndpointURL: URL { get }
}

public struct ProductionFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public let label = FirefoxAccountConfigurationLabel.production

    public let authEndpointURL = ProductionAuthEndpointURL
    public let oauthEndpointURL = ProductionOAuthEndpointURL
    public let profileEndpointURL = ProductionProfileEndpointURL
    public let signInURL = ProductionSignInURL
    public let settingsURL = ProductionSettingsURL
    public let forceAuthURL = ProductionForceAuthURL

    public var sync15Configuration: Sync15Configuration {
        return ProductionSync15Configuration(prefs: self.prefs)
    }

    public let pushConfiguration: PushConfiguration = FirefoxPushConfiguration()
}

public struct ProductionSync15Configuration: Sync15Configuration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public var tokenServerEndpointURL: URL {
        return overriddenCustomSyncTokenServerURI(prefs: prefs) ?? ProductionTokenServerEndpointURL
    }
}

public struct ChinaEditionFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public let label = FirefoxAccountConfigurationLabel.chinaEdition

    public let authEndpointURL = ChinaAuthEndpointURL
    public let oauthEndpointURL = ChinaOAuthEndpointURL
    public let profileEndpointURL = ChinaProfileEndpointURL
    public let signInURL = ChinaSignInURL
    public let settingsURL = ChinaSettingsURL
    public let forceAuthURL = ChinaForceAuthURL

    public var sync15Configuration: Sync15Configuration {
        return ChinaEditionSync15Configuration(prefs: self.prefs)
    }

    public let pushConfiguration: PushConfiguration = FirefoxPushConfiguration()
}

public struct ChinaEditionSync15Configuration: Sync15Configuration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public var tokenServerEndpointURL: URL {
        return overriddenCustomSyncTokenServerURI(prefs: prefs) ?? ChinaTokenServerEndpointURL
    }
}

public struct StageFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public let label = FirefoxAccountConfigurationLabel.stage

    public let authEndpointURL = StageAuthEndpointURL
    public let oauthEndpointURL = StageOAuthEndpointURL
    public let profileEndpointURL = StageProfileEndpointURL
    public let signInURL = StageSignInURL
    public let settingsURL = StageSettingsURL
    public let forceAuthURL = StageForceAuthURL

    public var sync15Configuration: Sync15Configuration {
        return StageSync15Configuration(prefs: self.prefs)
    }

    public var pushConfiguration: PushConfiguration {
        #if MOZ_CHANNEL_RELEASE
            return FirefoxStagingPushConfiguration()
        #elseif MOZ_CHANNEL_BETA
            return FirefoxBetaStagingPushConfiguration()
        #elseif MOZ_CHANNEL_FENNEC
            return FennecStagingPushConfiguration()
        #endif
    }
}

public struct StageSync15Configuration: Sync15Configuration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public var tokenServerEndpointURL: URL {
        return overriddenCustomSyncTokenServerURI(prefs: prefs) ?? StageTokenServerEndpointURL
    }
}

public struct LatestDevFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public let label = FirefoxAccountConfigurationLabel.latestDev

    public let authEndpointURL = LatestDevAuthEndpointURL
    public let oauthEndpointURL = LatestDevOAuthEndpointURL
    public let profileEndpointURL = LatestDevProfileEndpointURL
    public let signInURL = LatestDevSignInURL
    public let settingsURL = LatestDevSettingsURL
    public let forceAuthURL = LatestDevForceAuthURL

    public var sync15Configuration: Sync15Configuration {
        return StageSync15Configuration(prefs: self.prefs)
    }

    public let pushConfiguration: PushConfiguration = FennecPushConfiguration()
}

public struct StableDevFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public let label = FirefoxAccountConfigurationLabel.stableDev

    public let authEndpointURL = StableDevAuthEndpointURL
    public let oauthEndpointURL = StableDevOAuthEndpointURL
    public let profileEndpointURL = StableDevProfileEndpointURL
    public let signInURL = StableDevSignInURL
    public let settingsURL = StableDevSettingsURL
    public let forceAuthURL = StableDevForceAuthURL

    public var sync15Configuration: Sync15Configuration {
        return StageSync15Configuration(prefs: self.prefs)
    }

    public let pushConfiguration: PushConfiguration = FennecPushConfiguration()
}

public struct CustomFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public let label = FirefoxAccountConfigurationLabel.custom

    public var authEndpointURL: URL {
        if prefs.boolForKey(PrefsKeys.KeyUseCustomAccountAutoconfig) ?? false,
            let authServer = prefs.stringForKey(PrefsKeys.KeyCustomSyncAuth), let url = URL(string: authServer + "/v1") {
            return url
        }

        // If somehow an invalid URL was stored, fallback to the Production URL
        return ProductionAuthEndpointURL
    }

    public var oauthEndpointURL: URL {
        if prefs.boolForKey(PrefsKeys.KeyUseCustomAccountAutoconfig) ?? false,
            let oauthServer = prefs.stringForKey(PrefsKeys.KeyCustomSyncOauth), let url = URL(string: oauthServer + "/v1") {
            return url
        }

        // If somehow an invalid URL was stored, fallback to the Production URL
        return ProductionOAuthEndpointURL
    }

    public var profileEndpointURL: URL {
        if prefs.boolForKey(PrefsKeys.KeyUseCustomAccountAutoconfig) ?? false,
            let profileServer = prefs.stringForKey(PrefsKeys.KeyCustomSyncProfile), let url = URL(string: profileServer + "/v1") {
            return url
        }

        // If somehow an invalid URL was stored, fallback to the Production URL
        return ProductionProfileEndpointURL
    }

    public var signInURL: URL {
        if prefs.boolForKey(PrefsKeys.KeyUseCustomAccountAutoconfig) ?? false,
            let signIn = prefs.stringForKey(PrefsKeys.KeyCustomSyncWeb), let url = URL(string: signIn + "/signin?service=sync&context=fx_ios_v1") {
            return url
        }

        // If somehow an invalid URL was stored, fallback to the Production URL
        return ProductionSignInURL
    }

    public var forceAuthURL: URL {
        if prefs.boolForKey(PrefsKeys.KeyUseCustomAccountAutoconfig) ?? false,
            let forceAuth = prefs.stringForKey(PrefsKeys.KeyCustomSyncWeb), let url = URL(string: forceAuth + "/force_auth?service=sync&context=fx_ios_v1") {
            return url
        }

        // If somehow an invalid URL was stored, fallback to the Production URL
        return ProductionForceAuthURL
    }

    public var settingsURL: URL {
        if prefs.boolForKey(PrefsKeys.KeyUseCustomAccountAutoconfig) ?? false,
            let settings = prefs.stringForKey(PrefsKeys.KeyCustomSyncWeb), let url = URL(string: settings + "/settings?service=sync&context=fx_ios_v1") {
            return url
        }

        // If somehow an invalid URL was stored, fallback to the Production URL
        return ProductionSettingsURL
    }

    public var sync15Configuration: Sync15Configuration {
        return CustomSync15Configuration(prefs: self.prefs)
    }

    public let pushConfiguration: PushConfiguration = FirefoxPushConfiguration()
}

public struct CustomSync15Configuration: Sync15Configuration {
    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public var prefs: Prefs

    public var tokenServerEndpointURL: URL {
        if prefs.boolForKey(PrefsKeys.KeyUseCustomAccountAutoconfig) ?? false,
            let tokenServer = prefs.stringForKey(PrefsKeys.KeyCustomSyncToken), let url = URL(string: tokenServer + "/1.0/sync/1.5") {
            return overriddenCustomSyncTokenServerURI(prefs: prefs) ?? url
        }

        // If somehow an invalid URL was stored, fallback to the Production URL
        return overriddenCustomSyncTokenServerURI(prefs: prefs) ?? ProductionTokenServerEndpointURL
    }
}

// If the user specifies a custom Sync token server URI in the "Advanced Sync Settings"
// menu (toggled via enabling the Debug menu), this will return a URL to override
// whatever Sync token server they would otherwise get by default. They can also provide
// an autoconfig URI that gives a full set of URLs to use for FxA/Sync and still also
// provide a custom Sync token server URI to override that value with.
fileprivate func overriddenCustomSyncTokenServerURI(prefs: Prefs) -> URL? {
    guard prefs.boolForKey(PrefsKeys.KeyUseCustomSyncTokenServerOverride) ?? false, let customSyncTokenServerURIString = prefs.stringForKey(PrefsKeys.KeyCustomSyncTokenServerOverride) else {
        return nil
    }

    return URL(string: customSyncTokenServerURIString)
}
