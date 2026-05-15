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
