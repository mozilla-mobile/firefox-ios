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
    private var allowPolicyRawValue: Int {
        return WKNavigationActionPolicy.allow.rawValue
    }
    private lazy var allowBlockingUniversalLinksPolicy = WKNavigationActionPolicy(rawValue: allowPolicyRawValue + 2)

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        tabManager = MockTabManager()
    }

    override func tearDown() {
        profile = nil
        tabManager = nil
        super.tearDown()
    }

    // MARK: - Decide policy
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

    func testWebViewDecidePolicyForNavigationAction_addRequestToPending() {
        let subject = createSubject()
        let tab = createTab()
        let url = URL(string: "https://www.example.com")!
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { _ in
            XCTAssertNotNil(subject.pendingRequests[url.absoluteString])
        }
    }

    func testWebViewDecidePolicyForNavigationAction_allowsLoading_whenBlobURLsWithNavigationTypeOther() {
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

    func testWebViewDecidePolicyForNavigationAction_cancelLoading() {
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

    // MARK: - Authentication

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

    private func createSubject() -> BrowserViewController {
        let subject = BrowserViewController(profile: profile, tabManager: tabManager)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func anyWebView(url: URL? = nil) -> MockTabWebView {
        let tab = MockTabWebView(frame: .zero, configuration: WKWebViewConfiguration(), windowUUID: .XCTestDefaultUUID)
        tab.loadedURL = url
        return tab
    }

    private func createTab(isPrivate: Bool = false) -> Tab {
        let tab = Tab(profile: profile, isPrivate: isPrivate, windowUUID: .XCTestDefaultUUID)
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
}

class MockNavigationAction: WKNavigationAction {
    private var type: WKNavigationType?
    private var urlRequest: URLRequest

    override var navigationType: WKNavigationType {
        return type ?? .other
    }

    override var request: URLRequest {
        return urlRequest
    }

    init(url: URL, type: WKNavigationType? = nil) {
        self.type = type
        self.urlRequest = URLRequest(url: url)
    }
}

class MockURLAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}

    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
