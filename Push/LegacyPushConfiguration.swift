// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum LegacyPushConfigurationLabel: String {
    case fennec = "Fennec"
    case fennecEnterprise = "FennecEnterprise"
    case firefoxBeta = "FirefoxBeta"
    case firefoxNightlyEnterprise = "FirefoxNightly"
    case firefox = "Firefox"

    public func toConfiguration() -> LegacyPushConfiguration {
        switch self {
        case .fennec: return FennecPushConfiguration()
        case .fennecEnterprise: return FennecEnterprisePushConfiguration()
        case .firefoxBeta: return FirefoxBetaPushConfiguration()
        case .firefoxNightlyEnterprise: return FirefoxNightlyEnterprisePushConfiguration()
        case .firefox: return FirefoxPushConfiguration()
        }
    }
}

public protocol LegacyPushConfiguration {
    var label: LegacyPushConfigurationLabel { get }

    /// The associated autopush server should speak the protocol documented at
    /// http://autopush.readthedocs.io/en/latest/http.html#push-service-http-api
    /// /v1/{type}/{app_id}
    /// type == apns
    /// app_id == the “platform” or “channel” of development (e.g. “firefox”, “beta”, “gecko”, etc.)
    var endpointURL: NSURL { get }
}

public struct FennecPushConfiguration: LegacyPushConfiguration {
    public init() {}
    public let label = LegacyPushConfigurationLabel.fennec
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/fennec")!
}

public struct FennecStagingPushConfiguration: LegacyPushConfiguration {
    public init() {}
    public let label = LegacyPushConfigurationLabel.fennec
    public let endpointURL = NSURL(string: "https://updates-autopush.stage.mozaws.net/v1/apns/fennec")!
}

public struct FennecEnterprisePushConfiguration: LegacyPushConfiguration {
    public init() {}
    public let label = LegacyPushConfigurationLabel.fennecEnterprise
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/fennecenterprise")!
}

public struct FirefoxBetaPushConfiguration: LegacyPushConfiguration {
    public init() {}
    public let label = LegacyPushConfigurationLabel.firefoxBeta
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/firefoxbeta")!
}

public struct FirefoxBetaStagingPushConfiguration: LegacyPushConfiguration {
    public init() {}
    public let label = LegacyPushConfigurationLabel.firefoxBeta
    public let endpointURL = NSURL(string: "https://updates-autopush.stage.mozaws.net/v1/apns/firefoxbeta")!
}

public struct FirefoxNightlyEnterprisePushConfiguration: LegacyPushConfiguration {
    public init() {}
    public let label = LegacyPushConfigurationLabel.firefoxNightlyEnterprise
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/firefoxnightlyenterprise")!
}

public struct FirefoxPushConfiguration: LegacyPushConfiguration {
    public init() {}
    public let label = LegacyPushConfigurationLabel.firefox
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/firefox")!
}

public struct FirefoxStagingPushConfiguration: LegacyPushConfiguration {
    public init() {}
    public let label = LegacyPushConfigurationLabel.firefox
    public let endpointURL = NSURL(string: "https://updates-autopush.stage.mozaws.net/v1/apns/firefox")!
}
