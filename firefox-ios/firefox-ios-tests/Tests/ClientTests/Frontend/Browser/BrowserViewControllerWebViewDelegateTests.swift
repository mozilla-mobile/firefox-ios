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

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        tabManager = MockTabManager()
        fileManager = MockFileManager()
    }

    override func tearDown() {
        profile = nil
        tabManager = nil
        fileManager = nil
        super.tearDown()
    }

    // MARK: - Decide policy for navigation action
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

    func testWebViewDecidePolicyForNavigationAction_cancelLoading_whenLoadingLocalPDFurlPreviouslyDeleted() {
        let subject = createSubject()
        let tab = createTab()

        let pdfURL = URL(string: "file://test.pdf")!
        let sourceURL = URL(string: "https://www.example.com")!
        tab.restoreTemporaryDocumentSession([pdfURL: sourceURL])
        tabManager.tabs = [tab]

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: pdfURL,
                                                              type: .other)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

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

    // MARK: - Decide policy for navigation response
    func testWebViewDecidePolicyForNavigationResponse_cancelLoading_whenResponseIsPDFThatWasntDownloadedPreviously() {
        let subject = createSubject()
        let tab = createTab()

        let pdfURL = URL(string: "https://example.com/test.pdf")!
        let response = URLResponse(
            url: pdfURL,
            mimeType: MIMEType.PDF,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        subject.pendingRequests[pdfURL.absoluteString] = URLRequest(url: pdfURL)
        tabManager.tabs = [tab]

        subject.webView(tab.webView!, decidePolicyFor: MockNavigationResponse(response: response)) { policy in
            XCTAssertEqual(policy, .cancel)
        }
    }

    func testWebViewDecidePolicyForNavigationResponse_allowsLoading_whenResponseIsLocalPDFFileAlreadyDownloaded() {
        let subject = createSubject()
        let tab = createTab()

        let pdfURL = URL(string: "https://example.com/test.pdf")!
        let localPDFURL = URL(string: "file://test.pdf")!
        let response = URLResponse(
            url: localPDFURL,
            mimeType: MIMEType.PDF,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        fileManager.fileExists = true
        subject.pendingRequests[pdfURL.absoluteString] = URLRequest(url: pdfURL)
        tab.restoreTemporaryDocumentSession([localPDFURL: pdfURL])
        tabManager.tabs = [tab]

        subject.webView(tab.webView!, decidePolicyFor: MockNavigationResponse(response: response)) { policy in
            XCTAssertEqual(policy, .allow)
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
        let subject = BrowserViewController(
            profile: profile,
            tabManager: tabManager,
            mainQueue: MockDispatchQueue(),
            userInitiatedQueue: MockDispatchQueue()
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func anyWebView(url: URL? = nil) -> MockTabWebView {
        let tab = MockTabWebView(frame: .zero, configuration: WKWebViewConfiguration(), windowUUID: .XCTestDefaultUUID)
        tab.loadedURL = url
        return tab
    }

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

class MockNavigationResponse: WKNavigationResponse {
    private let _response: URLResponse
    private let _isMainFrame: Bool
    private let _canShowMIMEType: Bool

    override var response: URLResponse {
        return _response
    }

    override var isForMainFrame: Bool {
        return _isMainFrame
    }

    override var canShowMIMEType: Bool {
        return _canShowMIMEType
    }

    init(response: URLResponse,
         canShowMIMEType: Bool = true,
         isMainFrame: Bool = true) {
        self._response = response
        self._isMainFrame = isMainFrame
        self._canShowMIMEType = canShowMIMEType
        super.init()
    }
}

class MockURLAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}

    func cancel(_ challenge: URLAuthenticationChallenge) {}
}

class MockFileManager: FileManagerProtocol {
    var fileExistsCalled = 0
    var fileExists = false
    var urlsForDirectoryCalled = 0
    var contentOfDirectoryCalled = 0
    var removeItemAtPathCalled = 0
    var removeItemAtURLCalled = 0
    var copyItemCalled = 0
    var createDirectoryCalled = 0
    var contentOfDirectoryAtPathCalled = 0

    func fileExists(atPath path: String) -> Bool {
        fileExistsCalled += 1
        return fileExists
    }

    func urls(for directory: FileManager.SearchPathDirectory,
              in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        urlsForDirectoryCalled += 1
        return []
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        contentOfDirectoryCalled += 1
        return []
    }

    func contentsOfDirectoryAtPath(_ path: String, withFilenamePrefix prefix: String) throws -> [String] {
        contentOfDirectoryAtPathCalled += 1
        return []
    }

    func removeItem(atPath path: String) throws {
        removeItemAtPathCalled += 1
    }

    func removeItem(at url: URL) throws {
        removeItemAtURLCalled += 1
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        copyItemCalled += 1
    }

    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws {
        createDirectoryCalled += 1
    }
}
