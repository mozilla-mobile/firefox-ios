// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Network
import TestKit
import XCTest
@testable import Client

@MainActor
@available(iOS 17.0, *)
final class VPNProxySessionProviderTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        VPNProxySessionProvider.shared.update([])
    }

    override func tearDown() async throws {
        VPNProxySessionProvider.shared.update([])
        try await super.tearDown()
    }

    // MARK: - URLSession.sharedWithVPNProxy

    func test_sharedWithVPNProxy_withoutProxy_returnsSharedSession() {
        XCTAssertTrue(URLSession.sharedWithVPNProxy === URLSession.shared)
    }

    func test_sharedWithVPNProxy_withProxy_returnsProxiedSession() throws {
        if #unavailable(iOS 17.0) { throw XCTSkip("Requires iOS 17.0") }
        VPNProxySessionProvider.shared.update([makeProxyConfiguration()])

        let session = URLSession.sharedWithVPNProxy

        XCTAssertFalse(session === URLSession.shared)
        XCTAssertEqual(session.configuration.proxyConfigurations.count, 1)
    }

    // MARK: - Helpers

    private func makeProxyConfiguration() -> ProxyConfiguration {
        let hop = ProxyConfiguration.RelayHop(
            http2RelayEndpoint: .url(URL(string: "https://proxy.example.invalid/")!)
        )
        return ProxyConfiguration(relayHops: [hop])
    }
}
