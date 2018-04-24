/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum PushConfigurationLabel: String {
    case fennec = "Fennec"
    case fennecEnterprise = "FennecEnterprise"
    case firefoxBeta = "FirefoxBeta"
    case firefoxNightlyEnterprise = "FirefoxNightly"
    case firefox = "Firefox"

    public func toConfiguration() -> PushConfiguration {
        switch self {
        case .fennec: return FennecPushConfiguration()
        case .fennecEnterprise: return FennecEnterprisePushConfiguration()
        case .firefoxBeta: return FirefoxBetaPushConfiguration()
        case .firefoxNightlyEnterprise: return FirefoxNightlyEnterprisePushConfiguration()
        case .firefox: return FirefoxPushConfiguration()
        }
    }
}

public protocol PushConfiguration {
    var label: PushConfigurationLabel { get }

    /// The associated autopush server should speak the protocol documented at
    /// http://autopush.readthedocs.io/en/latest/http.html#push-service-http-api
    /// /v1/{type}/{app_id}
    /// type == apns
    /// app_id == the “platform” or “channel” of development (e.g. “firefox”, “beta”, “gecko”, etc.)
    var endpointURL: NSURL { get }
}

public struct FennecPushConfiguration: PushConfiguration {
    public init() {}
    public let label = PushConfigurationLabel.fennec
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/fennec")!
}

public struct FennecStagingPushConfiguration: PushConfiguration {
    public init() {}
    public let label = PushConfigurationLabel.fennec
    public let endpointURL = NSURL(string: "https://updates-autopush.stage.mozaws.net/v1/apns/fennec")!
}

public struct FennecEnterprisePushConfiguration: PushConfiguration {
    public init() {}
    public let label = PushConfigurationLabel.fennecEnterprise
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/fennecenterprise")!
}

public struct FirefoxBetaPushConfiguration: PushConfiguration {
    public init() {}
    public let label = PushConfigurationLabel.firefoxBeta
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/firefoxbeta")!
}

public struct FirefoxBetaStagingPushConfiguration: PushConfiguration {
    public init() {}
    public let label = PushConfigurationLabel.firefoxBeta
    public let endpointURL = NSURL(string: "https://updates-autopush.stage.mozaws.net/v1/apns/firefoxbeta")!
}

public struct FirefoxNightlyEnterprisePushConfiguration: PushConfiguration {
    public init() {}
    public let label = PushConfigurationLabel.firefoxNightlyEnterprise
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/firefoxnightlyenterprise")!
}

public struct FirefoxPushConfiguration: PushConfiguration {
    public init() {}
    public let label = PushConfigurationLabel.firefox
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/firefox")!
}

public struct FirefoxStagingPushConfiguration: PushConfiguration {
    public init() {}
    public let label = PushConfigurationLabel.firefox
    public let endpointURL = NSURL(string: "https://updates-autopush.stage.mozaws.net/v1/apns/firefox")!
}
