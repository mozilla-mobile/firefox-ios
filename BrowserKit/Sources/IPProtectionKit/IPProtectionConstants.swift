// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The backend environment the IP Protection App Attest (IPN)
public enum IPProtectionEnvironment: String, Sendable {
    case dev
    case stage
    case prod

    var baseURL: URL? {
        // TODO: Replace with the real IP Protection IPN hosts once the backend endpoints are provisioned.
        switch self {
        case .dev:
            return URL(string: "https://dev.guardian.nonprod.cloudops.mozgcp.net")
        case .stage:
            return URL(string: "https://stage.guardian.nonprod.cloudops.mozgcp.net")
        case .prod:
            return URL(string: "https://vpn.mozilla.org")
        }
    }
}

/// HTTP constants and endpoint builders for the IP Protection App Attest (IPN) auth flow.
public enum IPProtectionConstants {
    static let authorizationHeader = "Authorization"
    static let bearerPrefix = "Bearer "
    static let contentTypeHeader = "Content-Type"
    static let contentTypeJSON = "application/json"
    static let POST = "POST"
    static let GET = "GET"

    static func challengeEndpoint(with env: IPProtectionEnvironment) -> URL? {
        env.baseURL?.appendingPathComponent("api/v1/ipn/attest/challenge")
    }

    static func enrollmentEndpoint(with env: IPProtectionEnvironment) -> URL? {
        env.baseURL?.appendingPathComponent("api/v1/ipn/enrollment")
    }

    static func refreshEndpoint(with env: IPProtectionEnvironment) -> URL? {
        env.baseURL?.appendingPathComponent("api/v1/ipn/refresh")
    }

    static func tokenEndpoint(with env: IPProtectionEnvironment) -> URL? {
        env.baseURL?.appendingPathComponent("api/v1/ipn/token")
    }
}
