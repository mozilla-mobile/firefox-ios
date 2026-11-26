// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Network
import TestKit
import XCTest
@testable import SiteImageView

@MainActor
@available(iOS 17.0, *)
final class DefaultSiteImageDownloaderTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        VPNProxySessionProvider.shared.update([])
    }

    override func tearDown() async throws {
        VPNProxySessionProvider.shared.update([])
        try await super.tearDown()
    }

    func test_init_withoutProxy_hasNoProxyConfigurations() {
        let subject = createSubject()

        XCTAssertTrue(subject.sessionConfiguration.proxyConfigurations.isEmpty)
    }

    func test_init_withProxy_appliesProxyConfigurations() {
        VPNProxySessionProvider.shared.update([makeProxyConfiguration()])

        let subject = createSubject()

        XCTAssertEqual(subject.sessionConfiguration.proxyConfigurations.count, 1)
    }

    func test_init_afterProxyDisabled_hasNoProxyConfigurations() {
        VPNProxySessionProvider.shared.update([makeProxyConfiguration()])
        VPNProxySessionProvider.shared.update([])

        let subject = createSubject()

        XCTAssertTrue(subject.sessionConfiguration.proxyConfigurations.isEmpty)
    }

    // MARK: - Helpers

    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> DefaultSiteImageDownloader {
        let subject = DefaultSiteImageDownloader()
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func makeProxyConfiguration() -> ProxyConfiguration {
        let hop = ProxyConfiguration.RelayHop(
            http2RelayEndpoint: .url(URL(string: "https://proxy.example.invalid/")!)
        )
        return ProxyConfiguration(relayHops: [hop])
    }
}
