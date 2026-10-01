// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import WebEngine

// Exercises the data store via `WKHTTPCookieStore` rather than a real `WKWebView`:
// WKWebView navigation is non-deterministic in a unit-test target with no host
// `UIApplication` (`didFinish` does not fire reliably). The data store is the same
// surface a `WKWebView` writes through.
@MainActor
final class WKEngineConfigurationProviderIntegrationTests: XCTestCase {
    func testPrivateCookies_areClearedAfterSessionBoundary() async {
        let subject = createSubject()

        let firstStore = subject.createConfiguration(parameters: privateParams())
            .webViewConfiguration.websiteDataStore
        await setCookie(name: "leaked", value: "yes", in: firstStore)
        let firstCookies = await allCookies(in: firstStore)
        XCTAssertTrue(firstCookies.contains(where: { $0.name == "leaked" }))

        subject.endPrivateBrowsingSession()

        let secondStore = subject.createConfiguration(parameters: privateParams())
            .webViewConfiguration.websiteDataStore
        let secondCookies = await allCookies(in: secondStore)
        XCTAssertFalse(secondCookies.contains(where: { $0.name == "leaked" }))
    }

    func testPrivateCookies_areVisibleAcrossSiblingTabsWithinSession() async {
        let subject = createSubject()

        let firstStore = subject.createConfiguration(parameters: privateParams())
            .webViewConfiguration.websiteDataStore
        await setCookie(name: "shared", value: "visible", in: firstStore)

        let siblingStore = subject.createConfiguration(parameters: privateParams())
            .webViewConfiguration.websiteDataStore
        let siblingCookies = await allCookies(in: siblingStore)
        XCTAssertTrue(siblingCookies.contains(where: { $0.name == "shared" && $0.value == "visible" }))
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

    private func setCookie(name: String, value: String, in store: WKWebsiteDataStore) async {
        let cookie = HTTPCookie(properties: [
            .domain: "example.com",
            .path: "/",
            .name: name,
            .value: value,
            .secure: "FALSE"
        ])!
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.httpCookieStore.setCookie(cookie) {
                continuation.resume()
            }
        }
    }

    private func allCookies(in store: WKWebsiteDataStore) async -> [HTTPCookie] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[HTTPCookie], Never>) in
            store.httpCookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
    }
}
