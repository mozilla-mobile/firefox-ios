// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation

/// A Proxy Pass contains the Token to Authenticate to the Proxy Servers
public struct VPNProxyPass: Equatable, Sendable {
    public let bearerToken: String
    public let notBefore: Date
    public let expiresAt: Date
    public let usage: VPNProxyUsage? // TODO: FXIOS-17238 This shouldn't be nil in the real world case

    public init(bearerToken: String, notBefore: Date, expiresAt: Date, usage: VPNProxyUsage?) {
        self.bearerToken = bearerToken
        self.notBefore = notBefore
        self.expiresAt = expiresAt
        self.usage = usage
    }
}

public struct VPNProxyUsage: Equatable, Sendable {
    // Bytes the User can consume in each Period
    public let max: UInt64
    // Bytes the User has left in each Period
    public let remaining: UInt64
    // Date when the next Period begins
    public let reset: Date
    // For people in a promotion or that have a subscription
    public let unlimited: Bool

    /// Byte counts are BigInts serialized as strings; `resetAt` is Unix milliseconds.
    private struct EntitlementResponse: Decodable {
        let usageBytes: String
        let maxBytes: String
        let resetAt: Date
    }

    public init(max: UInt64, remaining: UInt64, reset: Date, unlimited: Bool) {
        self.max = max
        self.remaining = remaining
        self.reset = reset
        self.unlimited = unlimited
    }

    /// Reads Guardian's `X-Quota-*` headers; nil if any are missing or malformed.
    init?(response: URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse,
              let maxString = httpResponse.value(forHTTPHeaderField: VPNConstants.quotaLimitHeader),
              let max = UInt64(maxString),
              let remainingString = httpResponse.value(forHTTPHeaderField: VPNConstants.quotaRemainingHeader),
              let remaining = UInt64(remainingString),
              let resetString = httpResponse.value(forHTTPHeaderField: VPNConstants.quotaResetHeader),
              let reset = Self.parseISO8601(resetString)
        else { return nil }
        self.init(max: max, remaining: remaining, reset: reset, unlimited: false)
    }

    /// Decodes the `/ipn/entitlement` JSON body.
    init(entitlementData: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let entitlement = try decoder.decode(EntitlementResponse.self, from: entitlementData)
        guard let usage = UInt64(entitlement.usageBytes),
              let max = UInt64(entitlement.maxBytes)
        else {
            throw AppAttestServiceError.invalidPayload
        }
        self.init(
            max: max,
            remaining: usage >= max ? 0 : max - usage,
            reset: entitlement.resetAt,
            unlimited: false
        )
    }

    private static func parseISO8601(_ string: String) -> Date? {
        (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string))
            ?? (try? Date.ISO8601FormatStyle().parse(string))
    }
}
