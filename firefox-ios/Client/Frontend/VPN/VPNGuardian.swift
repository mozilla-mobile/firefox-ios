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
                return URL(string: "https://vpn-mozilla-nonprod-stage.global.ssl.fastly.net")!
            }
        }
    }

   /// A Proxy Pass contains the Token to Authenticate to the Proxy Servers
    struct ProxyPass {
        let bearerToken: String
        let notBefore: Date
        let expiresAt: Date
        let usage: ProxyUsage? // This shouldn't be nil in the real world case
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
        /// A rotation exhausted `rotationTimeout` without a usable pass.
        case rotationTimedOut
    }

    /// Rotation timings mirror the desktop/Android implementation in
    /// `toolkit/components/ipprotection/IPPProxyManager.sys.mjs`, so all three platforms
    /// behave the same against Guardian.

    /// How long before a pass's `expiresAt` we proactively rotate. Matches desktop's
    /// `ProxyPass.ROTATION_TIME`, which puts `rotationTimePoint` two minutes before expiry.
    static let rotateBeforeExpiry: TimeInterval = 120
    /// Floor on the scheduled delay, so a pass that arrives already near expiry can't spin the
    /// rotation loop. Matches `browser.ipProtection.guardian.minRotationInterval`.
    static let minRotationInterval: TimeInterval = 1
    /// First backoff delay after a retryable failure, doubled on each subsequent attempt.
    /// Matches `browser.ipProtection.guardian.retryAfter`.
    static let rotationRetryDelay: TimeInterval = 0.5
    /// Ceiling on a single fetch attempt. Matches
    /// `browser.ipProtection.guardian.attemptTimeout`.
    static let rotationAttemptTimeout: TimeInterval = 10
    /// Ceiling on a whole rotation including retries, after which we give up rather than
    /// retry forever. Matches `browser.ipProtection.guardian.timeout`.
    static let rotationTimeout: TimeInterval = 30

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

    /// Emits a fresh `ProxyPass` shortly before the previous one expires. Cancel the consuming
    /// task to stop rotation — the stream will tear down its internal fetch loop via
    /// `onTermination`.
    ///
    /// The stream finishes once a rotation fails terminally, mirroring desktop's
    /// `rotateProxyPass`, which does not reschedule its timer after a failure. The consumer
    /// therefore treats stream completion as "rotation is no longer running".
    ///
    /// In-flight WebKit requests continue with the old bearer token thanks to the proxy's
    /// grace period; only new requests pick up the rotated header.
    func passRotation(after initial: ProxyPass) -> AsyncStream<ProxyPass> {
        AsyncStream { continuation in
            let task = Task { [weak self] in
                var current = initial
                while !Task.isCancelled {
                    let refreshAt = current.expiresAt.addingTimeInterval(-Self.rotateBeforeExpiry)
                    let sleepInterval = max(Self.minRotationInterval, refreshAt.timeIntervalSinceNow)
                    guard (try? await Self.sleep(seconds: sleepInterval)) != nil else { break }
                    guard let self, !Task.isCancelled else { break }

                    do {
                        let new = try await self.rotatePass()
                        current = new
                        continuation.yield(new)
                    } catch is CancellationError {
                        break
                    } catch {
                        // Desktop surfaces this as an error state on a still-active proxy. We
                        // stop rotating and let the consumer decide; the current pass stays
                        // valid until it expires.
                        self.logger.log(
                            "Pass rotation failed terminally, stopping rotation: \(error)",
                            level: .warning,
                            category: .sync
                        )
                        break
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    /// Fetches a replacement pass, retrying retryable failures with exponential backoff until
    /// `rotationTimeout` is spent. Mirrors desktop's `#attemptPassRotation`: server errors,
    /// timeouts and offline errors are retried; anything else fails the rotation immediately.
    private func rotatePass() async throws -> ProxyPass {
        let deadline = Date().addingTimeInterval(Self.rotationTimeout)
        var delay = Self.rotationRetryDelay

        while !Task.isCancelled {
            do {
                return try await getPass()
            } catch {
                guard Self.isRetryable(error) else { throw error }

                let remaining = deadline.timeIntervalSinceNow
                guard remaining > 0 else { throw GuardianError.rotationTimedOut }

                logger.log(
                    "Pass rotation attempt failed: \(error). Retrying in \(delay)s.",
                    level: .warning,
                    category: .sync
                )
                try await Self.sleep(seconds: min(delay, remaining))
                delay *= 2
            }
        }

        throw CancellationError()
    }

    /// Retryable failures are the ones desktop loops on: 5xx responses, a timed-out attempt,
    /// and being offline. A 4xx or an unparseable body will not fix itself, so it fails fast.
    private static func isRetryable(_ error: Error) -> Bool {
        switch error {
        case GuardianError.http(let status) where (500...599).contains(status):
            return true
        case let urlError as URLError:
            return retryableURLErrorCodes.contains(urlError.code)
        default:
            return false
        }
    }

    private static let retryableURLErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .cannotFindHost,
        .cannotConnectToHost,
        .dnsLookupFailed,
        .networkConnectionLost,
        .notConnectedToInternet
    ]

    private static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
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
        // Bounds a single attempt so the retry loop in `rotatePass` keeps making progress
        // against its overall budget, as desktop's per-attempt AbortController does.
        request.timeoutInterval = Self.rotationAttemptTimeout

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
//        let usage = try parseUsage(response: http)

        return ProxyPass(
            bearerToken: parsed.token,
            notBefore: nbf,
            expiresAt: exp,
            usage: nil
        )
    }

    private struct JWTClaims: Decodable {
        let nbf: TimeInterval
        let exp: TimeInterval
    }

    private static func decodeJWTClaims(_ jwt: String) throws -> JWTClaims {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else {
            throw GuardianError.bodyInvalid
        }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard let data = Data(base64Encoded: payload) else {
            throw GuardianError.bodyInvalid
        }
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
