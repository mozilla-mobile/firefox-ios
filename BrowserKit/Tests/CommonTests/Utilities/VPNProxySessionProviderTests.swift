// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Network
import TestKit
import XCTest
@testable import Common

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

    // MARK: - proxyConfigurations

    func test_proxyConfigurations_byDefault_isEmpty() {
        let subject = createSubject()

        XCTAssertTrue(subject.proxyConfigurations.isEmpty)
    }

    func test_proxyConfigurations_afterUpdate_returnsUpdatedConfigs() {
        let subject = createSubject()

        subject.update([makeProxyConfiguration(), makeProxyConfiguration()])

        XCTAssertEqual(subject.proxyConfigurations.count, 2)
    }

    // MARK: - isProxyActive

    func test_isProxyActive_byDefault_isFalse() {
        let subject = createSubject()

        XCTAssertFalse(subject.isProxyActive)
    }

    func test_isProxyActive_withProxy_isTrue() {
        let subject = createSubject()

        subject.update([makeProxyConfiguration()])

        XCTAssertTrue(subject.isProxyActive)
    }

    func test_isProxyActive_afterProxyDisabled_isFalse() {
        let subject = createSubject()
        subject.update([makeProxyConfiguration()])

        subject.update([])

        XCTAssertFalse(subject.isProxyActive)
    }

    // MARK: - session

    func test_session_withoutProxy_returnsSharedSession() {
        let subject = createSubject()

        XCTAssertTrue(subject.session === URLSession.shared)
    }

    func test_session_withProxy_returnsSessionWithProxyConfigurations() {
        let subject = createSubject()
        subject.update([makeProxyConfiguration()])

        let session = subject.session

        XCTAssertFalse(session === URLSession.shared)
        XCTAssertEqual(session.configuration.proxyConfigurations.count, 1)
    }

    func test_session_withProxy_returnsSameSessionOnRepeatedAccess() {
        let subject = createSubject()
        subject.update([makeProxyConfiguration()])

        XCTAssertTrue(subject.session === subject.session)
    }

    func test_session_afterProxyUpdate_returnsNewSession() {
        let subject = createSubject()
        subject.update([makeProxyConfiguration()])
        let firstSession = subject.session

        subject.update([makeProxyConfiguration(), makeProxyConfiguration()])
        let secondSession = subject.session

        XCTAssertFalse(firstSession === secondSession)
        XCTAssertEqual(secondSession.configuration.proxyConfigurations.count, 2)
    }

    func test_session_afterProxyDisabled_returnsSharedSession() {
        let subject = createSubject()
        subject.update([makeProxyConfiguration()])
        _ = subject.session

        subject.update([])

        XCTAssertTrue(subject.session === URLSession.shared)
    }

    // MARK: - URLSessionConfiguration.withVPNProxy

    func test_withVPNProxy_withoutProxy_hasNoProxyConfigurations() {
        let configuration = URLSessionConfiguration.ephemeral.withVPNProxy()

        XCTAssertTrue(configuration.proxyConfigurations.isEmpty)
    }

    func test_withVPNProxy_withProxy_appliesProxyConfigurations() throws {
        if #unavailable(iOS 17.0) { throw XCTSkip("Requires iOS 17.0") }
        VPNProxySessionProvider.shared.update([makeProxyConfiguration()])

        let configuration = URLSessionConfiguration.ephemeral.withVPNProxy()

        XCTAssertEqual(configuration.proxyConfigurations.count, 1)
    }

    // MARK: - Helpers

    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> VPNProxySessionProvider {
        let subject = VPNProxySessionProvider()
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
