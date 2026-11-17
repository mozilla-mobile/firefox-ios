// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Common
import Shared
import Foundation
import VPNKit

protocol VPNGuardianProviding: Sendable {
    func getPass() async throws -> VPNProxyPass
    func passRotation(after initial: VPNProxyPass) -> AsyncThrowingStream<VPNProxyPass, Error>
}

final class VPNGuardian: VPNGuardianProviding {
    struct Server {
        let hostname: String
        let port: UInt16
        let city: String
        let countryCode: String
    }

    enum GuardianError: Error {
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
    /// Ceiling on a whole rotation including retries, after which we give up rather than
    /// retry forever. Matches `browser.ipProtection.guardian.timeout`.
    static let rotationTimeout: TimeInterval = 30

    private let tokenProvider: VPNTokenProviding
    private let logger: Logger

    private static let retryableURLErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .cannotFindHost,
        .cannotConnectToHost,
        .dnsLookupFailed,
        .networkConnectionLost,
        .notConnectedToInternet
    ]

    init(
        tokenProvider: VPNTokenProviding,
        logger: Logger
    ) {
        self.tokenProvider = tokenProvider
        self.logger = logger
    }

    convenience init?(authCreator: VPNAuthCreating, prefs: Prefs, logger: Logger) {
        guard let tokenProvider = authCreator.makeTokenProvider(using: prefs) else {
            logger.log(
                "VPN token provider unavailable (App Attest is not supported on simulator)",
                level: .warning,
                category: .vpn
            )
            return nil
        }

        self.init(tokenProvider: tokenProvider, logger: logger)
    }

    func getPass() async throws -> VPNProxyPass {
        return try await tokenProvider.proxyToken()
    }

    /// Emits a fresh `VPNProxyPass` shortly before the previous one expires. Cancel the consuming
    /// task to stop rotation — the stream will tear down its internal fetch loop via
    /// `onTermination`.
    ///
    /// The stream throws once a rotation fails terminally, mirroring desktop's
    /// `rotateProxyPass`, which does not reschedule its timer after a failure. Cancellation
    /// finishes the stream without throwing.
    ///
    /// In-flight WebKit requests continue with the old bearer token thanks to the proxy's
    /// grace period. Only new requests pick up the rotated header.
    func passRotation(after initial: VPNProxyPass) -> AsyncThrowingStream<VPNProxyPass, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [weak self] in
                var current = initial
                while !Task.isCancelled {
                    let refreshAt = current.expiresAt.addingTimeInterval(-Self.rotateBeforeExpiry)
                    let sleepInterval = max(Self.minRotationInterval, refreshAt.timeIntervalSinceNow)
                    try? await Self.sleep(seconds: sleepInterval)
                    guard let self, !Task.isCancelled else { break }

                    do {
                        let new = try await self.rotatePass()
                        current = new
                        continuation.yield(new)
                    } catch is CancellationError {
                        break
                    } catch {
                        continuation.finish(throwing: error)
                        return
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
    private func rotatePass() async throws -> VPNProxyPass {
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
                    category: .vpn
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
        case AppAttestServiceError.serverError(let status, _) where (500...599).contains(status):
            return true
        case let urlError as URLError:
            return retryableURLErrorCodes.contains(urlError.code)
        default:
            return false
        }
    }

    private static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
    }
}
