// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

final class VPNGuardian: Sendable {
    enum Configuration {
        case prod
        case staging

        var baseURL: URL {
            switch self {
            case .prod:
                return URL(string: "https://vpn.mozilla.com")!
            case .staging:
                return URL(string: "https://vpn.mozilla.org")!
            }
        }
    }

   /// A Proxy Pass contains the Token to Authenticate to the Proxy Servers
    struct ProxyPass {
        let bearerToken: String
        let notBefore: Date
        let expiresAt: Date
        let usage: ProxyUsage
    }

    struct ProxyUsage {
        // Bytes the User can consume in each Period
        let max: Int64
        // Bytes the User has left in each Period
        let remaining: Int64
        // Date when the next Period begins
        let reset: Date
    }

    struct Server {
        let hostname: String
        let port: UInt16
        let city: String
        let countryCode: String
    }

    /// An Entitlement describes that the level of access.
    struct Entitlement {
        /**
         * True when the User has upgraded to a subscription to *Mozilla* VPN.
         */
        let subscribed: Bool
        let uid: Int64
        // The Amount of Bytes the user can consume per period
        let maxBytes: Int64
    }

    enum GuardianError: Error {
        case http(status: Int)
        case bodyInvalid
    }

    /// How long before a pass's `expiresAt` we proactively rotate. The proxy pass has a
    /// ~15 min lifetime; rotating 3 min early gives the round-trip headroom and avoids
    /// brief windows where new requests would race the expiry.
    static let rotateBeforeExpiry: TimeInterval = 180
    /// Backoff delay after a failed rotation fetch.
    static let rotationRetryDelay: TimeInterval = 30

    private let authHeaders: [String: String]
    private let configuration: Configuration
    private let logger: Logger

    init(
        authHeaders: [String: String],
        configuration: Configuration,
        logger: Logger
    ) {
        self.authHeaders = authHeaders
        self.configuration = configuration
        self.logger = logger
    }

    func getPass() async throws -> ProxyPass {
        return try await fetchProxyPass(authHeaders: authHeaders)
    }

    /// Emits a fresh `ProxyPass` shortly before the previous one expires, indefinitely.
    /// Cancel the consuming task to stop rotation — the stream will tear down its
    /// internal fetch loop via `onTermination`.
    ///
    /// In-flight WebKit requests continue with the old bearer token thanks to the proxy's
    /// grace period; only new requests pick up the rotated header.
    func passRotation(after initial: ProxyPass) -> AsyncStream<ProxyPass> {
        AsyncStream { continuation in
            let task = Task { [weak self] in
                var current = initial
                while !Task.isCancelled {
                    let refreshAt = current.expiresAt.addingTimeInterval(-Self.rotateBeforeExpiry)
                    let sleepInterval = max(0, refreshAt.timeIntervalSinceNow)
                    do {
                        try await Task.sleep(
                            nanoseconds: UInt64(sleepInterval * Double(NSEC_PER_SEC))
                        )
                    } catch {
                        break
                    }
                    guard let self, !Task.isCancelled else { break }
                    do {
                        let new = try await self.getPass()
                        current = new
                        continuation.yield(new)
                    } catch {
                        self.logger.log(
                            "Pass rotation failed: \(error). Retrying in \(Self.rotationRetryDelay)s.",
                            level: .warning,
                            category: .sync
                        )
                        try? await Task.sleep(
                            nanoseconds: UInt64(Self.rotationRetryDelay * Double(NSEC_PER_SEC))
                        )
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    private func fetchProxyPass(authHeaders: [String: String]) async throws -> ProxyPass {
        let url = configuration.baseURL.appendingPathComponent("api/v1/foxfooding/token")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (name, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GuardianError.bodyInvalid
        }
        guard http.statusCode == 200 else {
            throw GuardianError.http(status: http.statusCode)
        }

        struct TokenResponse: Decodable {
            let token: String
        }

        let parsed: TokenResponse
        do {
            parsed = try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw GuardianError.bodyInvalid
        }

        let claims = try Self.decodeJWTClaims(parsed.token)
        let nbf = Date(timeIntervalSince1970: claims.nbf)
        let exp = Date(timeIntervalSince1970: claims.exp)
        let usage = try parseUsage(response: http)

        return ProxyPass(
            bearerToken: parsed.token,
            notBefore: nbf,
            expiresAt: exp,
            usage: usage
        )
    }

    private struct JWTClaims: Decodable {
        let nbf: TimeInterval
        let exp: TimeInterval
    }

    private static func decodeJWTClaims(_ jwt: String) throws -> JWTClaims {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { throw GuardianError.bodyInvalid }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard let data = Data(base64Encoded: payload) else { throw GuardianError.bodyInvalid }
        do {
            return try JSONDecoder().decode(JWTClaims.self, from: data)
        } catch {
            throw GuardianError.bodyInvalid
        }
    }

    private func parseUsage(response: HTTPURLResponse) throws -> ProxyUsage {
        guard let limitStr = response.value(forHTTPHeaderField: "X-Quota-Limit"),
              let limit = Int64(limitStr),
              let remainingStr = response.value(forHTTPHeaderField: "X-Quota-Remaining"),
              let remaining = Int64(remainingStr),
              let resetStr = response.value(forHTTPHeaderField: "X-Quota-Reset")
        else {
            throw GuardianError.bodyInvalid
        }

        do {
            let reset = try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(resetStr)
            return ProxyUsage(max: limit, remaining: remaining, reset: reset)
        } catch {
            throw GuardianError.bodyInvalid
        }
    }
}
