// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Storage
import WebKit

@testable import Client

class BrowserViewControllerWebViewDelegateTests: XCTestCase {
    var subject: BrowserViewController!
    var profile: MockProfile!
    var tabManager: TabManager!
    var tabManagerDelegate: TabManagerNavDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        tabManager = TabManagerImplementation(profile: profile,
                                              uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        subject = BrowserViewController(profile: profile, tabManager: tabManager)
        tabManagerDelegate = TabManagerNavDelegate()
    }

    override func tearDown() {
        AppContainer.shared.reset()
        profile = nil
        tabManager = nil
        subject = nil
        tabManagerDelegate = nil
        super.tearDown()
    }

    func testWebViewDidReceiveChallenge_MethodServerTrust() {
        tabManagerDelegate.insert(subject)

        tabManagerDelegate.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodServerTrust")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    func testWebViewDidReceiveChallenge_MethodHTTPDigest() {
        tabManagerDelegate.insert(subject)

        tabManagerDelegate.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodHTTPDigest")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    func testWebViewDidReceiveChallenge_MethodHTTPNTLM() {
        tabManagerDelegate.insert(subject)

        tabManagerDelegate.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodNTLM")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    func testWebViewDidReceiveChallenge_MethodHTTPBasic() {
        tabManagerDelegate.insert(subject)

        tabManagerDelegate.webView(
            anyWebView(),
            didReceive: anyAuthenticationChallenge(for: "NSURLAuthenticationMethodHTTPBasic")
        ) { disposition, credential in
            XCTAssertEqual(disposition, .performDefaultHandling)
            XCTAssertNil(credential)
        }
    }

    private func anyWebView() -> WKWebView {
        return WKWebView(frame: CGRect(width: 100, height: 100))
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

class MockURLAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}

    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
