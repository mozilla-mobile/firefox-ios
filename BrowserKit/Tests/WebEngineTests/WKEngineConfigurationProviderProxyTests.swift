// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Network
import XCTest
import WebKit
@testable import WebEngine

@MainActor
@available(iOS 17.0, *)
final class WKEngineConfigurationProviderProxyTests: XCTestCase {
    override func tearDown() async throws {
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], forcingSessionReset: false)
        try await super.tearDown()
    }

    func testApplyProxyConfigurations_withConfigs_enablesProxy() {
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([makeProxyConfiguration()])

        XCTAssertTrue(DefaultWKEngineConfigurationProvider.isProxyEnabled)
    }

    func testApplyProxyConfigurations_withEmptyConfigs_disablesProxy() {
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([makeProxyConfiguration()])

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([])

        XCTAssertFalse(DefaultWKEngineConfigurationProvider.isProxyEnabled)
    }

    func testApplyProxyConfigurations_forcingSessionReset_appendsTriggerToBothStores() {
        let subject = createSubject()

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([makeProxyConfiguration()])

        XCTAssertEqual(normalStore(subject).proxyConfigurations.count, 2)
        XCTAssertEqual(privateStore(subject).proxyConfigurations.count, 2)
    }

    func testApplyProxyConfigurations_withEmptyConfigsForcingSessionReset_keepsOnlyTrigger() {
        let subject = createSubject()

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([])

        XCTAssertEqual(normalStore(subject).proxyConfigurations.count, 1)
        XCTAssertEqual(privateStore(subject).proxyConfigurations.count, 1)
        XCTAssertFalse(DefaultWKEngineConfigurationProvider.isProxyEnabled)
    }

    func testApplyProxyConfigurations_withoutSessionReset_assignsConfigsAsIs() {
        let subject = createSubject()

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations(
            [makeProxyConfiguration()],
            forcingSessionReset: false
        )

        XCTAssertEqual(normalStore(subject).proxyConfigurations.count, 1)
        XCTAssertEqual(privateStore(subject).proxyConfigurations.count, 1)
        XCTAssertTrue(DefaultWKEngineConfigurationProvider.isProxyEnabled)
    }

    func testEndPrivateBrowsingSession_carriesProxyConfigurationsToNewPrivateStore() {
        let subject = createSubject()
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([makeProxyConfiguration()])
        let beforeStore = privateStore(subject)

        subject.endPrivateBrowsingSession()

        let afterStore = privateStore(subject)
        XCTAssertFalse(beforeStore === afterStore)
        XCTAssertEqual(afterStore.proxyConfigurations.count, beforeStore.proxyConfigurations.count)
    }

    func testEndPrivateBrowsingSession_withoutProxy_leavesNewPrivateStoreUnproxied() {
        let subject = createSubject()

        subject.endPrivateBrowsingSession()

        XCTAssertTrue(privateStore(subject).proxyConfigurations.isEmpty)
    }

    // MARK: - Helpers

    private func createSubject() -> DefaultWKEngineConfigurationProvider {
        return DefaultWKEngineConfigurationProvider()
    }

    private func makeProxyConfiguration() -> ProxyConfiguration {
        let hop = ProxyConfiguration.RelayHop(
            http2RelayEndpoint: .url(URL(string: "https://proxy.invalid/")!)
        )
        return ProxyConfiguration(relayHops: [hop])
    }

    private func normalStore(_ subject: DefaultWKEngineConfigurationProvider) -> WKWebsiteDataStore {
        return subject.createConfiguration(parameters: parameters(isPrivate: false))
            .webViewConfiguration.websiteDataStore
    }

    private func privateStore(_ subject: DefaultWKEngineConfigurationProvider) -> WKWebsiteDataStore {
        return subject.createConfiguration(parameters: parameters(isPrivate: true))
            .webViewConfiguration.websiteDataStore
    }

    private func parameters(isPrivate: Bool) -> WKWebViewParameters {
        return WKWebViewParameters(
            blockPopups: true,
            isPrivate: isPrivate,
            autoPlay: .all,
            schemeHandler: WKInternalSchemeHandler()
        )
    }
}
