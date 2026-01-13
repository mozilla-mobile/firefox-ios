// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import WebKit
import Shared

@testable import Client

class BrowserViewControllerWebViewDelegateTests: XCTestCase {
    private var profile: MockProfile!
    private var tabManager: MockTabManager!
    private var fileManager: MockFileManager!
    private var allowPolicyRawValue: Int {
        return WKNavigationActionPolicy.allow.rawValue
    }
    private lazy var allowBlockingUniversalLinksPolicy = WKNavigationActionPolicy(rawValue: allowPolicyRawValue + 2)

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        tabManager = MockTabManager()
        fileManager = MockFileManager()
        setWebEngineIntegrationEnabled(false)
    }

    override func tearDown() async throws {
        profile = nil
        tabManager = nil
        fileManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func testWKUIDelegate_isBrowserWebUIDelegate_whenWebEngineIntegrationIsEnabled() {
        let subject = createSubject()

        setWebEngineIntegrationEnabled(true)

        XCTAssertTrue(subject.wkUIDelegate is BrowserWebUIDelegate)
    }

    @MainActor
    func testWKUIDelegate_isBrowserViewController_whenWebEngineIntegrationIsDisabled() {
        let subject = createSubject()

        XCTAssertTrue(subject.wkUIDelegate is BrowserViewController)
    }

    // MARK: - Decide policy for navigation action
    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelWhenTabNotInTabManager() {
        let subject = createSubject()
        let url = URL(string: "https://example.com")!
        let tab = createTab()

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelFacetimeScheme() {
        let subject = createSubject()
        let url = URL(string: "facetime://testuser")!
        let tab = createTab()
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelFacetimeAudioScheme() {
        let subject = createSubject()
        let url = URL(string: "facetime-audio://testuser")!
        let tab = createTab()
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelTelScheme() {
        let subject = createSubject()
        let url = URL(string: "tel://3484563742")!
        let tab = createTab()
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelAppStoreScheme() {
        let subject = createSubject()
        let url = URL(string: "itms-apps://test-app")!
        let tab = createTab()
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelAppStoreURL() {
        let subject = createSubject()
        let url = URL(string: "https://apps.apple.com/test-app")!
        let tab = createTab()
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_allowsAnyWebsite_withNormalTabs() {
        let subject = createSubject()
        let tab = createTab()
        let url = URL(string: "https://www.example.com")!
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, .allow)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_allowsAnyWebsiteBlockingUniversalLink_whenOptionEnabled() {
        let subject = createSubject()
        let tab = createTab()
        let url = URL(string: "https://www.example.com")!
        tabManager.tabs = [tab]
        profile.prefs.setBool(true, forKey: PrefsKeys.BlockOpeningExternalApps)

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, self.allowBlockingUniversalLinksPolicy)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_allowsAnyWebsite_andBlockUniversalLinksWithPrivateTab() {
        let subject = createSubject()
        let tab = createTab(isPrivate: true)
        let url = URL(string: "https://www.example.com")!
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { policy in
            XCTAssertEqual(policy, self.allowBlockingUniversalLinksPolicy)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_addRequestToPending() {
        let subject = createSubject()
        let tab = createTab()
        let url = URL(string: "https://www.example.com")!
        tabManager.tabs = [tab]
        let expectation = XCTestExpectation()

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { _ in
            ensureMainThread {
                XCTAssertNotNil(subject.pendingRequests[url.absoluteString])
                expectation.fulfill()
            }
        }

        wait(for: [expectation])
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_allowsLoading_whenBlobSchemeWithNavigationTypeOther() {
        let subject = createSubject()
        let tab = createTab()
        let blob = URL(string: "blob://blobfile")!
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: blob,
                                                              type: .other)) { policy in
            XCTAssertEqual(policy, .allow)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelLoading_withBlobScheme() {
        let subject = createSubject()
        let tab = createTab()
        let blob = URL(string: "blob://blobfile")!
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: blob,
                                                              type: .backForward)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_allowsLoading_whenLoadingLocalPDFurlPreviouslyDownloaded() {
        let subject = createSubject()
        let tab = createTab()

        let pdfURL = URL(string: "file://test.pdf")!
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: pdfURL,
                                                              type: .other)) { policy in
            XCTAssertEqual(policy, .allow)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_allowMarketPlaceScheme_whenUserAction() {
        let subject = MockBrowserViewController(
            profile: profile,
            tabManager: tabManager,
            userInitiatedQueue: MockDispatchQueue()
        )
        subject.mockIsMainFrameNavigation = true
        trackForMemoryLeaks(subject)

        let url = URL(string: "marketplace-kit://install?exampleApp.com")!
        let tab = createTab()
        tabManager.tabs = [tab]
        let navigationAction = MockNavigationAction(url: url, type: .linkActivated)

        subject.webView(tab.webView!,
                        decidePolicyFor: navigationAction) { policy in
            XCTAssertEqual(policy, .allow)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelMarketPlaceScheme_whenNotMainFrame() {
        let subject = MockBrowserViewController(
            profile: profile,
            tabManager: tabManager,
            userInitiatedQueue: MockDispatchQueue()
        )
        subject.mockIsMainFrameNavigation = false
        trackForMemoryLeaks(subject)

        let url = URL(string: "marketplace-kit://install?exampleApp.com")!
        let tab = createTab()
        tabManager.tabs = [tab]
        let navigationAction = MockNavigationAction(url: url, type: .linkActivated)

        subject.webView(tab.webView!,
                        decidePolicyFor: navigationAction) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    @MainActor
    func testWebViewDecidePolicyForNavigationAction_cancelMarketPlaceScheme_whenReloadAction() {
        let subject = MockBrowserViewController(
            profile: profile,
            tabManager: tabManager,
            userInitiatedQueue: MockDispatchQueue()
        )
        subject.mockIsMainFrameNavigation = true
        trackForMemoryLeaks(subject)

        let url = URL(string: "marketplace-kit://install?exampleApp.com")!
        let tab = createTab()
        tabManager.tabs = [tab]
        let navigationAction = MockNavigationAction(url: url, type: .reload)

        subject.webView(tab.webView!,
                        decidePolicyFor: navigationAction) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    // MARK: - Authentication

    @MainActor
    func testWebViewDidReceiveChallenge_MethodServerTrust() {
        let subject = createSubject()

        subject.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodServerTrust")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    @MainActor
    func testWebViewDidReceiveChallenge_MethodHTTPDigest() {
        let subject = createSubject()

        subject.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodHTTPDigest")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    @MainActor
    func testWebViewDidReceiveChallenge_MethodHTTPNTLM() {
        let subject = createSubject()

        subject.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodNTLM")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    @MainActor
    func testWebViewDidReceiveChallenge_MethodHTTPBasic() {
        let subject = createSubject()

        subject.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodHTTPBasic")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    @MainActor
    private func createSubject() -> BrowserViewController {
        let subject = BrowserViewController(
            profile: profile,
            tabManager: tabManager,
            userInitiatedQueue: MockDispatchQueue()
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    @MainActor
    private func anyWebView(url: URL? = nil) -> MockTabWebView {
        let tab = MockTabWebView(frame: .zero, configuration: WKWebViewConfiguration(), windowUUID: .XCTestDefaultUUID)
        tab.loadedURL = url
        return tab
    }

    @MainActor
    private func createTab(isPrivate: Bool = false) -> Tab {
        let tab = Tab(
            profile: profile,
            isPrivate: isPrivate,
            windowUUID: .XCTestDefaultUUID,
            fileManager: fileManager
        )
        let webView = MockTabWebView(tab: tab)
        tab.webView = webView
        return tab
    }

    private func anyAuthenticationChallenge(for authenticationMethod: String) -> URLAuthenticationChallenge {
        let protectionSpace = URLProtectionSpace(host: "https:test.com",
                                                 port: 443,
                                                 protocol: nil,
                                                 realm: nil,
                                                 authenticationMethod: authenticationMethod)
        return URLAuthenticationChallenge(protectionSpace: protectionSpace,
                                          proposedCredential: nil,
                                          previousFailureCount: 0,
                                          failureResponse: nil,
                                          error: nil,
                                          sender: MockURLAuthenticationChallengeSender())
    }

    private func getCertificate(_ file: String) -> SecCertificate {
        let path = Bundle(for: type(of: self)).path(forResource: file, ofType: "pem")
        let data = try? Data(contentsOf: URL(fileURLWithPath: path!))
        return SecCertificateCreateWithData(nil, data! as CFData)!
    }

    private func setWebEngineIntegrationEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.webEngineIntegrationRefactor.with { _, _ in
            return WebEngineIntegrationRefactor(enabled: enabled)
        }
    }

    // This test is being skipped because there are some very strange side effects
    // in webView didFinish because the profile database is not being stubbed out
    // TODO: FXIOS-13435 to look in to this
    @MainActor
    func testWebViewDidFinishNavigation_takeScreenshotWhenTabIsSelected() {
        let subject = createSubject()
        let screenshotHelper = MockScreenshotHelper(controller: subject)
        subject.screenshotHelper = screenshotHelper

        let tab = createTab()
        tabManager.tabs = [tab]
        tabManager.selectedTab = tab

        subject.webView(tab.webView!, didFinish: nil)

        XCTAssertTrue(screenshotHelper.takeScreenshotCalled)
    }
}
