// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import enum MozillaAppServices.BridgeType
import enum MozillaAppServices.PushHttpProtocol
import struct MozillaAppServices.PushConfiguration

public struct KnownPushHost {
    public static let prod = "updates.push.services.mozilla.com"
    public static let stage = "updates-autopush.stage.mozaws.net"
}

enum InvalidSchemeError: Error {
    case InvalidScheme(String)
}

public enum PushConfigurationLabel: String {
    case fennec = "fennec"
    case fennecEnterprise = "fennecenterprise"
    case firefoxBeta = "firefoxbeta"
    case firefoxNightlyEnterprise = "firefoxnightlyenterprise"
    case firefox = "firefox"

    static func fromScheme(scheme: String) throws -> PushConfigurationLabel {
        switch scheme {
        case "Fennec": return .fennec
        case "FennecEnterprise": return .fennecEnterprise
        case "FirefoxBeta": return .firefoxBeta
        case "FirefoxNightly": return .firefoxNightlyEnterprise
        case "Firefox": return .firefox
        default: throw InvalidSchemeError.InvalidScheme(scheme)
        }
    }

    public func toConfiguration(dbPath: String) -> PushConfiguration {
        return PushConfiguration(
            serverHost: KnownPushHost.prod,
            httpProtocol: PushHttpProtocol.https,
            bridgeType: BridgeType.apns,
            senderId: self.rawValue,
            databasePath: dbPath,
            verifyConnectionRateLimiter: nil
        )
    }

    public func toStagingConfiguration(dbPath: String) -> PushConfiguration {
        return PushConfiguration(
            serverHost: KnownPushHost.stage,
            httpProtocol: PushHttpProtocol.https,
            bridgeType: BridgeType.apns,
            senderId: self.rawValue,
            databasePath: dbPath,
            verifyConnectionRateLimiter: nil
        )
    }

    public func toLocalConfiguration(host: String, dbPath: String) -> PushConfiguration {
        return PushConfiguration(
            serverHost: host,
            httpProtocol: PushHttpProtocol.http,
            bridgeType: BridgeType.apns,
            senderId: self.rawValue,
            databasePath: dbPath,
            verifyConnectionRateLimiter: nil
        )
    }
}
