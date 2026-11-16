// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import VPNKit

final class MockVPNServerManager: VPNServerManaging, @unchecked Sendable {
    var server: VPNGuardian.Server? = VPNGuardian.Server(
        hostname: "proxy.example",
        port: 443,
        city: "NYC",
        countryCode: "US"
    )
    var didFallBack = false
    var selectServerCalled = 0
    var selectServerCountryCodes: [String?] = []

    func selectServer(countryCode: String?, environment: VPNEnvironment) async -> VPNServerSelection? {
        selectServerCalled += 1
        selectServerCountryCodes.append(countryCode)
        return server.map { VPNServerSelection(server: $0, didFallBack: didFallBack) }
    }
}
