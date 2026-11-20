// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import VPNKit
@testable import Client

final class MockVPNGuardian: VPNGuardianProviding, @unchecked Sendable {
    var passResult: Result<VPNProxyPass, Error> = .success(
        VPNProxyPass(
            bearerToken: "initial-token",
            notBefore: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            usage: VPNProxyUsage(max: 1_000, remaining: 1_000, reset: .distantFuture, unlimited: false)
        )
    )
    var usageResult: Result<VPNProxyUsage, Error> = .success(
        VPNProxyUsage(max: 0, remaining: 0, reset: Date(), unlimited: false)
    )
    var passRotationInitialPasses: [VPNProxyPass] = []
    var onPassRotation: (() -> Void)?
    let rotation = AsyncThrowingStream<VPNProxyPass, Error>.makeStream()

    func getPass() async throws -> VPNProxyPass {
        return try passResult.get()
    }

    func getUsage() async throws -> VPNProxyUsage {
        return try usageResult.get()
    }

    func passRotation(after initial: VPNProxyPass) -> AsyncThrowingStream<VPNProxyPass, Error> {
        passRotationInitialPasses.append(initial)
        onPassRotation?()
        return rotation.stream
    }
}
