// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import WebKit

@testable import Client

class BrowserViewControllerWebViewDelegateTests: XCTestCase {
    var subject: BrowserViewController!
    var profile: MockProfile!
    var tabManager: TabManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        tabManager = TabManagerImplementation(profile: profile,
                                              uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        subject = BrowserViewController(profile: profile, tabManager: tabManager)
    }

    override func tearDown() {
        // DependencyHelperMock().reset()
        profile = nil
        tabManager = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Decide policy

    private let allowBlockingUniversalLinkPolicy = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2)

    func testWebViewDecidePolicyForNavigationAction_shouldAllow() {
        let subject = createSubject()

        subject.webView(anyWebView(), decidePolicyFor: MockNavigationAction(type: .linkActivated)) { policy in
            
        }
    }

    func testWebViewDidReceiveChallenge_MethodServerTrust() {
        subject.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodServerTrust")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    func testWebViewDidReceiveChallenge_MethodHTTPDigest() {
        subject.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodHTTPDigest")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    func testWebViewDidReceiveChallenge_MethodHTTPNTLM() {
        subject.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodNTLM")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    func testWebViewDidReceiveChallenge_MethodHTTPBasic() {
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

    private func anyWebView(url: URL? = nil) -> WKWebView {
        let tab = MockTabWebView(frame: .zero, configuration: WKWebViewConfiguration(), windowUUID: .XCTestDefaultUUID)
        tab.loadedURL = url
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

    override var navigationType: WKNavigationType {
        return type ?? .other
    }

    init(type: WKNavigationType? = nil) {
        self.type = type
    }
}

class MockURLAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}

    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
