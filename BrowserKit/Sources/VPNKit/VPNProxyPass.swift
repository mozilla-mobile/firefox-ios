// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
    public let max: Int64
    // Bytes the User has left in each Period
    public let remaining: Int64
    // Date when the next Period begins
    public let reset: Date
    // For people in a promotion or that have a subscription
    public let unlimited: Bool

    public init(max: Int64, remaining: Int64, reset: Date, unlimited: Bool) {
        self.max = max
        self.remaining = remaining
        self.reset = reset
        self.unlimited = unlimited
    }
}
