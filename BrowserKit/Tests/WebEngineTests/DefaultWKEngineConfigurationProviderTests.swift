// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import TestKit
import XCTest
import WebKit
@testable import WebEngine

@MainActor
final class DefaultWKEngineConfigurationProviderTests: XCTestCase {
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

    func testWebTransport_isDisabledBeforeiOS27_2() throws {
        guard #unavailable(iOS 27.2) else { throw XCTSkip("WebTransport stays on from iOS 27.2") }
        let subject = createSubject()

        let preferences = subject.createConfiguration(parameters: normalParams()).webViewConfiguration.preferences

        XCTAssertEqual(try webTransportEnabled(on: preferences), false)
    }

    func testWebTransport_isDisabledForPrivateTabsBeforeiOS27_2() throws {
        guard #unavailable(iOS 27.2) else { throw XCTSkip("WebTransport stays on from iOS 27.2") }
        let subject = createSubject()

        let preferences = subject.createConfiguration(parameters: privateParams()).webViewConfiguration.preferences

        XCTAssertEqual(try webTransportEnabled(on: preferences), false)
    }

    func testWebTransport_keepsWebKitDefaultFromiOS27_2() throws {
        guard #available(iOS 27.2, *) else { throw XCTSkip("WebTransport is disabled before iOS 27.2") }
        let subject = createSubject()

        let preferences = subject.createConfiguration(parameters: normalParams()).webViewConfiguration.preferences

        XCTAssertEqual(try webTransportEnabled(on: preferences), try webTransportEnabled(on: WKPreferences()))
    }

    func testDisableWebTransport_logsWhenTheFeatureKeyIsMissing() {
        let logger = MockLogger()
        let subject = createSubject(logger: logger)

        subject.disableWebTransport(on: WKPreferences(), featureKey: "NotARealWebKitFeature")

        XCTAssertEqual(logger.savedLevel, .warning)
        XCTAssertEqual(logger.savedCategory, .webview)
        XCTAssertTrue(logger.savedMessage?.contains("NotARealWebKitFeature") ?? false)
    }

    func testDisableWebTransport_doesNotLogWhenTheFlagIsSet() throws {
        let logger = MockLogger()
        let subject = createSubject(logger: logger)
        let preferences = WKPreferences()
        _ = try webTransportEnabled(on: preferences)

        subject.disableWebTransport(on: preferences)

        XCTAssertNil(logger.savedMessage)
        XCTAssertEqual(try webTransportEnabled(on: preferences), false)
    }

    // MARK: - Helpers

    private func webTransportEnabled(on preferences: WKPreferences) throws -> Bool {
        let isEnabledSelector = NSSelectorFromString("_isEnabledForFeature:")
        guard preferences.responds(to: isEnabledSelector),
              let features = (WKPreferences.self as AnyObject).value(forKey: "_features") as? [NSObject],
              let webTransport = features.first(where: { $0.value(forKey: "key") as? String == "WebTransportEnabled" })
        else { throw XCTSkip("This WebKit has no WebTransport feature flag") }
        typealias IsEnabled = @convention(c) (AnyObject, Selector, AnyObject) -> Bool
        let isEnabled = unsafeBitCast(preferences.method(for: isEnabledSelector), to: IsEnabled.self)
        return isEnabled(preferences, isEnabledSelector, webTransport)
    }

    private func createSubject(logger: Logger = MockLogger()) -> DefaultWKEngineConfigurationProvider {
        return DefaultWKEngineConfigurationProvider(logger: logger)
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
