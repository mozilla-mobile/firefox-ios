// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockVPNGuardian: VPNGuardianProviding, @unchecked Sendable {
    var passResult: Result<VPNGuardian.ProxyPass, Error> = .success(
        VPNGuardian.ProxyPass(
            bearerToken: "initial-token",
            notBefore: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            usage: nil
        )
    )
    var passRotationInitialPasses: [VPNGuardian.ProxyPass] = []
    var onPassRotation: (() -> Void)?
    let rotation = AsyncStream<VPNGuardian.ProxyPass>.makeStream()

    func getPass() async throws -> VPNGuardian.ProxyPass {
        return try passResult.get()
    }

    func passRotation(after initial: VPNGuardian.ProxyPass) -> AsyncStream<VPNGuardian.ProxyPass> {
        passRotationInitialPasses.append(initial)
        onPassRotation?()
        return rotation.stream
    }
}
