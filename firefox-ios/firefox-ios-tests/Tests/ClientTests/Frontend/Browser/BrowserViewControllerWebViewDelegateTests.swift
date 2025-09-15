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
        setWebEngineIntegrationEnabled(false)
    }

    override func tearDown() {
        profile = nil
        tabManager = nil
        fileManager = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testWKUIDelegate_isBrowserWebUIDelegate_whenWebEngineIntegrationIsEnabled() {
        let subject = createSubject()

        setWebEngineIntegrationEnabled(true)

        XCTAssertTrue(subject.wkUIDelegate is BrowserWebUIDelegate)
    }

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

        subject.webView(tab.webView!,
                        decidePolicyFor: MockNavigationAction(url: url,
                                                              type: .linkActivated)) { _ in
            XCTAssertNotNil(subject.pendingRequests[url.absoluteString])
        }
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

    private func createSubject() -> BrowserViewController {
        let subject = BrowserViewController(
            profile: profile,
            tabManager: tabManager,
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

    private func setWebEngineIntegrationEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.webEngineIntegrationRefactor.with { _, _ in
            return WebEngineIntegrationRefactor(enabled: enabled)
        }
    }

    // This test is being skipped because there are some very strange side effects
    // in webView didFinish because the profile database is not being stubbed out
    // TODO: FXIOS-13435 to look in to this
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

final class MockFileManager: FileManagerProtocol, @unchecked Sendable {
    var fileExistsCalled = 0
    var fileExists = false
    var urlsForDirectoryCalled = 0
    var contentOfDirectoryCalled = 0
    var removeItemAtPathCalled = 0
    var removeItemAtURLCalled = 0
    var copyItemCalled = 0
    var createDirectoryCalled = 0
    var contentOfDirectoryAtPathCalled = 0

    /// Fires every time `removeItem(at: URL)` is called. This is useful for tests that fire this on a background thread
    /// (e.g. in a deinit) and we want to wait for an expectation of a file removal to be fulfilled.
    /// Closure contains the updated value of `removeItemAtURLCalled`.
    var removeItemAtURLDispatch: ((Int) -> Void)?

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

    func contentsOfDirectoryAtPath(
        _ path: String,
        withFilenamePrefix prefix: String
    ) throws -> [String] {
        contentOfDirectoryAtPathCalled += 1
        return []
    }

    func removeItem(atPath path: String) throws {
        removeItemAtPathCalled += 1
    }

    func removeItem(at url: URL) throws {
        removeItemAtURLCalled += 1
        removeItemAtURLDispatch?(removeItemAtURLCalled)
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        copyItemCalled += 1
    }

    func createDirectory(
        atPath path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        createDirectoryCalled += 1
    }

    func contents(atPath path: String) -> Data? {
        return nil
    }

    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        return []
    }

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [FileAttributeKey: Any]?
    ) -> Bool {
        return true
    }
}
