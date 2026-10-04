// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import WebEngine

@MainActor
final class WKEngineConfigurationProviderTests: XCTestCase {
    func testPrivateStore_isSharedWithinSession() {
        let subject = createSubject()

        let first = subject.createConfiguration(parameters: privateParams())
        let second = subject.createConfiguration(parameters: privateParams())

        XCTAssertTrue(
            first.webViewConfiguration.websiteDataStore === second.webViewConfiguration.websiteDataStore
        )
    }

    func testPrivateStore_isSharedAcrossWindows() {
        // Each window owns its own provider, but private tabs must share cookies app-wide.
        let firstWindow = createSubject()
        let secondWindow = createSubject()

        let first = firstWindow.createConfiguration(parameters: privateParams())
        let second = secondWindow.createConfiguration(parameters: privateParams())

        XCTAssertTrue(
            first.webViewConfiguration.websiteDataStore === second.webViewConfiguration.websiteDataStore
        )
    }

    func testPrivateStore_isFreshAcrossSessionBoundary() {
        let subject = createSubject()

        let beforeStore = subject.createConfiguration(parameters: privateParams())
            .webViewConfiguration.websiteDataStore
        subject.endPrivateBrowsingSession()
        let afterStore = subject.createConfiguration(parameters: privateParams())
            .webViewConfiguration.websiteDataStore

        XCTAssertFalse(beforeStore === afterStore)
    }

    func testNormalStore_isUnaffectedBySessionBoundary() {
        let subject = createSubject()

        let before = subject.createConfiguration(parameters: normalParams())
            .webViewConfiguration.websiteDataStore
        subject.endPrivateBrowsingSession()
        let after = subject.createConfiguration(parameters: normalParams())
            .webViewConfiguration.websiteDataStore

        XCTAssertTrue(before === after)
        XCTAssertTrue(before.isPersistent)
    }

    func testPrivateStore_isNonPersistentAcrossBoundary() {
        let subject = createSubject()

        let beforeStore = subject.createConfiguration(parameters: privateParams())
            .webViewConfiguration.websiteDataStore
        XCTAssertFalse(beforeStore.isPersistent)

        subject.endPrivateBrowsingSession()

        let afterStore = subject.createConfiguration(parameters: privateParams())
            .webViewConfiguration.websiteDataStore
        XCTAssertFalse(afterStore.isPersistent)
    }

    @available(iOS 17.0, *)
    func testApplyProxyConfigurations_withConfigs_enablesProxy() {
        // Clear any existing proxy configs before testing
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], forcingSessionReset: false)

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([makeProxyConfiguration()])

        XCTAssertTrue(DefaultWKEngineConfigurationProvider.isProxyEnabled)
    }

    @available(iOS 17.0, *)
    func testApplyProxyConfigurations_withEmptyConfigs_disablesProxy() {
        // Clear any existing proxy configs before testing
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], forcingSessionReset: false)

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([makeProxyConfiguration()])

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([])

        XCTAssertFalse(DefaultWKEngineConfigurationProvider.isProxyEnabled)
    }

    @available(iOS 17.0, *)
    func testApplyProxyConfigurations_forcingSessionReset_appendsTriggerToBothStores() {
        // Clear any existing proxy configs before testing
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], forcingSessionReset: false)

        let subject = createSubject()

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([makeProxyConfiguration()])

        XCTAssertEqual(normalStore(subject).proxyConfigurations.count, 2)
        XCTAssertEqual(privateStore(subject).proxyConfigurations.count, 2)
    }

    @available(iOS 17.0, *)
    func testApplyProxyConfigurations_withEmptyConfigsForcingSessionReset_keepsOnlyTrigger() {
        // Clear any existing proxy configs before testing
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], forcingSessionReset: false)

        let subject = createSubject()

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([])

        XCTAssertEqual(normalStore(subject).proxyConfigurations.count, 1)
        XCTAssertEqual(privateStore(subject).proxyConfigurations.count, 1)
        XCTAssertFalse(DefaultWKEngineConfigurationProvider.isProxyEnabled)
    }

    @available(iOS 17.0, *)
    func testApplyProxyConfigurations_withoutSessionReset_assignsConfigsAsIs() {
        // Clear any existing proxy configs before testing
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], forcingSessionReset: false)

        let subject = createSubject()

        DefaultWKEngineConfigurationProvider.applyProxyConfigurations(
            [makeProxyConfiguration()],
            forcingSessionReset: false
        )

        XCTAssertEqual(normalStore(subject).proxyConfigurations.count, 1)
        XCTAssertEqual(privateStore(subject).proxyConfigurations.count, 1)
        XCTAssertTrue(DefaultWKEngineConfigurationProvider.isProxyEnabled)
    }

    @available(iOS 17.0, *)
    func testEndPrivateBrowsingSession_carriesProxyConfigurationsToNewPrivateStore() {
        // Clear any existing proxy configs before testing
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], forcingSessionReset: false)

        let subject = createSubject()
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([makeProxyConfiguration()])
        let beforeStore = privateStore(subject)

        subject.endPrivateBrowsingSession()

        let afterStore = privateStore(subject)
        XCTAssertFalse(beforeStore === afterStore)
        XCTAssertEqual(afterStore.proxyConfigurations.count, beforeStore.proxyConfigurations.count)
    }

    @available(iOS 17.0, *)
    func testEndPrivateBrowsingSession_withoutProxy_leavesNewPrivateStoreUnproxied() {
        // Clear any existing proxy configs before testing
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], forcingSessionReset: false)

        let subject = createSubject()

        subject.endPrivateBrowsingSession()

        XCTAssertTrue(privateStore(subject).proxyConfigurations.isEmpty)
    }

    // MARK: - Helpers
    @available(iOS 17.0, *)
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
    // MARK: - Helpers

    private func createSubject() -> DefaultWKEngineConfigurationProvider {
        return DefaultWKEngineConfigurationProvider()
    }

    private func privateParams() -> WKWebViewParameters {
        return WKWebViewParameters(
            blockPopups: true,
            isPrivate: true,
            autoPlay: .all,
            schemeHandler: WKInternalSchemeHandler()
        )
    }

    private func normalParams() -> WKWebViewParameters {
        return WKWebViewParameters(
            blockPopups: true,
            isPrivate: false,
            autoPlay: .all,
            schemeHandler: WKInternalSchemeHandler()
        )
    }
}
