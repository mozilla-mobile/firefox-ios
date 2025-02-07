// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine
import WebKit

final class WKEngineSessionTests: XCTestCase {
    private var configurationProvider: MockWKEngineConfigurationProvider!
    private var webViewProvider: MockWKWebViewProvider!
    private var contentScriptManager: MockWKContentScriptManager!
    private var userScriptManager: MockWKUserScriptManager!
    private var engineSessionDelegate: MockEngineSessionDelegate!
    private var findInPageDelegate: MockFindInPageHelperDelegate!
    private var metadataFetcher: MockMetadataFetcherHelper!

    override func setUp() {
        super.setUp()
        configurationProvider = MockWKEngineConfigurationProvider()
        webViewProvider = MockWKWebViewProvider()
        contentScriptManager = MockWKContentScriptManager()
        userScriptManager = MockWKUserScriptManager()
        engineSessionDelegate = MockEngineSessionDelegate()
        findInPageDelegate = MockFindInPageHelperDelegate()
        metadataFetcher = MockMetadataFetcherHelper()
    }

    override func tearDown() {
        super.tearDown()
        configurationProvider = nil
        webViewProvider = nil
        contentScriptManager = nil
        userScriptManager = nil
        engineSessionDelegate = nil
        findInPageDelegate = nil
        metadataFetcher = nil
    }

    // MARK: Load URL

    func testLoadURLGivenNormalURLThenLoad() {
        let subject = createSubject()
        let url = "https://example.com"
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let engineURL = EngineURL(browsingContext: context)!

        subject?.load(engineURL: engineURL)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, url)
    }

    func testLoadURLGivenReaderModeURLThenLoad() {
        let subject = createSubject()
        let url = "about:reader?url=http://example.com"
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let engineURL = EngineURL(browsingContext: context)!

        subject?.load(engineURL: engineURL)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString,
                       "http://localhost:0/reader-mode/page?url=http%3A%2F%2Fexample%2Ecom")
    }

    func testLoadURLGivenFileURLThenLoadFileURL() {
        let subject = createSubject()
        let url = "file://path/to/abc/dirA/A.html"
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let engineURL = EngineURL(browsingContext: context)!

        subject?.load(engineURL: engineURL)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadFileURLCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, "file://path/to/abc/dirA/A.html")
        XCTAssertEqual(webViewProvider.webView.loadFileReadAccessURL?.absoluteString, "file://path/to/abc/dirA/")
    }

    // MARK: Stop URL

    func testStopLoading() {
        let subject = createSubject()

        subject?.stopLoading()

        XCTAssertEqual(webViewProvider.webView.stopLoadingCalled, 1)
    }

    // MARK: Go back

    func testGoBack() {
        let subject = createSubject()

        subject?.goBack()

        XCTAssertEqual(webViewProvider.webView.goBackCalled, 1)
    }

    // MARK: Go forward

    func testGoForward() {
        let subject = createSubject()

        subject?.goForward()

        XCTAssertEqual(webViewProvider.webView.goForwardCalled, 1)
    }

    // MARK: Scroll to top

    func testScrollToTop() {
        let subject = createSubject()

        subject?.scrollToTop()

        let scrollView = webViewProvider.webView.engineScrollView as? MockEngineScrollView
        XCTAssertEqual(scrollView?.setContentOffsetCalled, 1)
        XCTAssertEqual(scrollView?.savedContentOffset, CGPoint.zero)
    }

    // MARK: Find in page

    func testFindInPageTextGivenFindAllThenJavascriptCalled() {
        let subject = createSubject()

        subject?.findInPage(text: "Banana", function: .find)

        XCTAssertEqual(webViewProvider.webView.evaluateJavaScriptCalled, 1)
        XCTAssertEqual(webViewProvider.webView.savedJavaScript, "__firefox__.find(\"Banana\")")
    }

    func testFindInPageTextGivenFindNextThenJavascriptCalled() {
        let subject = createSubject()

        subject?.findInPage(text: "Banana", function: .findNext)

        XCTAssertEqual(webViewProvider.webView.evaluateJavaScriptCalled, 1)
        XCTAssertEqual(webViewProvider.webView.savedJavaScript, "__firefox__.findNext(\"Banana\")")
    }

    func testFindInPageTextGivenFindPreviousThenJavascriptCalled() {
        let subject = createSubject()

        subject?.findInPage(text: "Banana", function: .findPrevious)

        XCTAssertEqual(webViewProvider.webView.evaluateJavaScriptCalled, 1)
        XCTAssertEqual(webViewProvider.webView.savedJavaScript, "__firefox__.findPrevious(\"Banana\")")
    }

    func testFindInPageTextGivenMaliciousAlertCodeThenIsSanitized() {
        let subject = createSubject()
        let maliciousTextWithAlert = "'; alert('Malicious code injected!'); '"
        subject?.findInPage(text: maliciousTextWithAlert, function: .find)

        XCTAssertEqual(webViewProvider.webView.evaluateJavaScriptCalled, 1)
        let result = "__firefox__.find(\"\'; alert(\'Malicious code injected!\'); \'\")"
        XCTAssertEqual(webViewProvider.webView.savedJavaScript, result)
    }

    func testFindInPageTextGivenMaliciousBrokenJsStringCodeThenIsSanitized() {
        let subject = createSubject()
        let maliciousText = "; maliciousFunction(); "
        subject?.findInPage(text: maliciousText, function: .find)

        XCTAssertEqual(webViewProvider.webView.evaluateJavaScriptCalled, 1)
        XCTAssertEqual(webViewProvider.webView.savedJavaScript, "__firefox__.find(\"; maliciousFunction(); \")")
    }

    func testFindInPageDoneThenJavascriptCalled() {
        let subject = createSubject()

        subject?.findInPageDone()

        XCTAssertEqual(webViewProvider.webView.evaluateJavaScriptCalled, 1)
        XCTAssertEqual(webViewProvider.webView.savedJavaScript, "__firefox__.findDone()")
    }

    func testFindInPageDelegateIsSetProperly() {
        let subject = createSubject()

        subject?.findInPageDelegate = findInPageDelegate
        guard let script = contentScriptManager.scripts[FindInPageContentScript.name()] as? FindInPageContentScript else {
            XCTFail("Failed to cast script to FindInPageContentScript in testFindInPageDelegateIsSetProperly")
            return
        }
        script.userContentController(didReceiveMessage: ["currentResult": 10])

        XCTAssertEqual(findInPageDelegate.didUpdateCurrentResultCalled, 1)
    }

    // MARK: Reload

    func testReloadThenCallsReloadFromOrigin() {
        let subject = createSubject()

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 1)
    }

    func testReloadWhenErrorPageThenLoadOriginalErrorPage() {
        let subject = createSubject()
        let errorPageURL = "errorpage"
        let internalURL = "internal://local/errorpage?url=\(errorPageURL)"
        let context = BrowsingContext(type: .internalNavigation, url: internalURL)
        let engineURL = EngineURL(browsingContext: context)!
        subject?.load(engineURL: engineURL)

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, errorPageURL)
    }

    func testReloadWhenHomepageThenLoadHomepageAsPrivileged() throws {
        let subject = createSubject()
        let internalURL = "internal://local/about/home"
        let context = BrowsingContext(type: .internalNavigation, url: internalURL)
        let engineURL = EngineURL(browsingContext: context)!
        subject?.load(engineURL: engineURL)

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2)
        let url = try XCTUnwrap(webViewProvider.webView.url)
        XCTAssertTrue(url.absoluteString.contains("internal://local/about/home?uuidkey="))
    }

    func testReloadWhenBypassCacheThenReloadBypassingCache() {
        let subject = createSubject()
        let url = "https://www.example.com"
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let engineURL = EngineURL(browsingContext: context)!
        subject?.load(engineURL: engineURL)

        subject?.reload(bypassCache: true)

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, url)
    }

    func testReloadWhenReloadFromOriginFailsThenRestoreWebviewWithLastRequest() {
        let subject = createSubject()
        let url = "https://www.example.com"
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let engineURL = EngineURL(browsingContext: context)!
        subject?.load(engineURL: engineURL)

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 1)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, url)
    }

    // MARK: Restore

    func testRestoreWhenNoLastRequestThenLoadNotCalled() {
        let subject = createSubject()
        let restoredState = Data()

        subject?.restore(state: restoredState)

        XCTAssertEqual(webViewProvider.webView.interactionState as? Data, restoredState)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
    }

    func testRestoreWhenHasLastRequestThenLoadISCalled() {
        let subject = createSubject()
        let restoredState = Data()
        let context = BrowsingContext(type: .internalNavigation, url: "https://example.com")
        let engineURL = EngineURL(browsingContext: context)!
        subject?.load(engineURL: engineURL)

        subject?.restore(state: restoredState)

        XCTAssertEqual(webViewProvider.webView.interactionState as? Data, restoredState)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2, "Load calls it once, then restore calls it again")
    }

    // MARK: Observers

    func testAddObserversWhenCreatedSubjectThenObserversAreAdded() {
        _ = createSubject()
        let expectedCount = WKEngineKVOConstants.allCases.count
        XCTAssertEqual(webViewProvider.webView.addObserverCalled,
                       expectedCount,
                       "There are \(expectedCount) KVO Constants")
    }

    func testRemoveObserversWhenCloseIsCalledThenObserversAreRemoved() {
        let subject = createSubject()

        subject?.close()

        let expectedCount = WKEngineKVOConstants.allCases.count
        XCTAssertEqual(webViewProvider.webView.removeObserverCalled,
                       expectedCount,
                       "There are \(expectedCount) KVO Constants")
    }

    func testCanGoBackGivenWebviewStateThenCallsNavigationStateChanged() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.canGoBack = true
        webViewProvider.webView.canGoForward = false

        subject?.observeValue(forKeyPath: "canGoBack",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onNavigationStateChangeCalled, 1)
        XCTAssertTrue(engineSessionDelegate.savedCanGoBack!)
        XCTAssertFalse(engineSessionDelegate.savedCanGoForward!)
    }

    func testCanGoForwardGivenWebviewStateThenCallsNavigationStateChanged() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.canGoBack = false
        webViewProvider.webView.canGoForward = true

        subject?.observeValue(forKeyPath: "canGoForward",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onNavigationStateChangeCalled, 1)
        XCTAssertFalse(engineSessionDelegate.savedCanGoBack!)
        XCTAssertTrue(engineSessionDelegate.savedCanGoForward!)
    }

    func testEstimatedProgressGivenWebviewStateThenCallsOnProgress() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.estimatedProgress = 70

        subject?.observeValue(forKeyPath: "estimatedProgress",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onProgressCalled, 1)
        XCTAssertEqual(engineSessionDelegate.savedProgressValue, 70)
    }

    func testLoadingGivenNoChangeThenDoesNotCallOnLoadingStateChange() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.observeValue(forKeyPath: "loading",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
    }

    func testLoadingGivenOldKeyThenDoesNotCallOnLoadingStateChange() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.observeValue(forKeyPath: "loading",
                              of: nil,
                              change: [.oldKey: true],
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
    }

    func testLoadingGivenNewKeyThenCallsOnLoadingStateChange() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.observeValue(forKeyPath: "loading",
                              of: nil,
                              change: [.newKey: true],
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 1)
        XCTAssertTrue(engineSessionDelegate.savedLoading!)
    }

    func testTitleChangeGivenEmptyTitleThenDoesntCallDelegate() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.title = nil

        subject?.observeValue(forKeyPath: "title",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertNil(subject?.sessionData.title)
        XCTAssertEqual(engineSessionDelegate.onTitleChangeCalled, 0)
    }

    func testTitleChangeGivenATitleThenCallsDelegate() {
        let expectedTitle = "Webview title"
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.title = expectedTitle

        subject?.observeValue(forKeyPath: "title",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(subject?.sessionData.title, expectedTitle)
        XCTAssertEqual(engineSessionDelegate.onTitleChangeCalled, 1)
    }

    func testURLChangeGivenNilURLThenDoesntCallDelegate() {
        let subject = createSubject()
        webViewProvider.webView.url = nil

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertNil(subject?.sessionData.url)
        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
    }

    func testURLChangeGivenAboutBlankWithNilURLThenDoesntCallDelegate() {
        let subject = createSubject()
        subject?.sessionData.url = URL(string: "about:blank")!
        webViewProvider.webView.url = nil

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
    }

    func testURLChangeGivenNotTheSameOriginThenDoesntCallDelegate() {
        let subject = createSubject()
        subject?.sessionData.url = URL(string: "www.example.com/path1")!
        webViewProvider.webView.url = URL(string: "www.anotherWebsite.com/path2")!

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
    }

    func testURLChangeGivenAboutBlankWithURLThenCallsDelegate() {
        let aboutBlankURL = URL(string: "about:blank")!
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        subject?.sessionData.url = aboutBlankURL
        webViewProvider.webView.url = aboutBlankURL

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(subject?.sessionData.url, aboutBlankURL)
        XCTAssertEqual(engineSessionDelegate.onLocationChangedCalled, 1)
    }

    func testURLChangeGivenLoadedURLWithURLThenCallsDelegate() {
        let loadedURL = URL(string: "www.example.com")!
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        subject?.sessionData.url = loadedURL
        webViewProvider.webView.url = loadedURL

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(subject?.sessionData.url, loadedURL)
        XCTAssertEqual(engineSessionDelegate.onLocationChangedCalled, 1)
    }

    // MARK: Page Zoom

    func testIncreaseZoom() {
        let subject = createSubject()
        // Check default zoom of 1.0
        XCTAssertEqual(webViewProvider.webView.pageZoom, 1.0)
        // Increase zoom
        subject?.updatePageZoom(.increase)
        // Assert zoom increased by expected step
        XCTAssertEqual(webViewProvider.webView.pageZoom, 1.0 + ZoomChangeValue.defaultStepIncrease)
    }

    func testDecreaseZoom() {
        let subject = createSubject()
        // Check default zoom of 1.0
        XCTAssertEqual(webViewProvider.webView.pageZoom, 1.0)
        // Increase zoom
        subject?.updatePageZoom(.decrease)
        // Assert zoom decreased by expected step
        XCTAssertEqual(webViewProvider.webView.pageZoom, 1.0 - ZoomChangeValue.defaultStepIncrease)
    }

    func testSetZoomLevelAndReset() {
        let subject = createSubject()
        // Check default zoom of 1.0
        XCTAssertEqual(webViewProvider.webView.pageZoom, 1.0)
        // Set explicit zoom level
        subject?.updatePageZoom(.set(0.8))
        // Assert zoom at expected level
        XCTAssertEqual(webViewProvider.webView.pageZoom, 0.8)

        // Reset zoom level
        subject?.updatePageZoom(.reset)
        // Check default zoom of 1.0
        XCTAssertEqual(webViewProvider.webView.pageZoom, 1.0)
    }

    // MARK: Metadata parser

    func testFetchMetadataGivenProperURLChangeThenFetchMetadata() {
        let loadedURL = URL(string: "www.example.com")!
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        subject?.sessionData.url = loadedURL
        webViewProvider.webView.url = loadedURL

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(metadataFetcher.fetchFromSessionCalled, 1)
        XCTAssertEqual(metadataFetcher.savedURL, loadedURL)
    }

    func testFetchMetadataGivenDidFinishNavigationThenFetchMetadata() {
        let loadedURL = URL(string: "www.example.com")!
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.url = loadedURL

        // FXIOS-8477 cannot test easily right now, need changes
//        let navigation = WKNavigation()
//        subject?.webView(webViewProvider.webView, didFinish: navigation)

//        XCTAssertEqual(metadataFetcher.fetchFromSessionCalled, 1)
//        XCTAssertEqual(metadataFetcher.savedURL, loadedURL)
    }

    // MARK: Error page

    func testReceivedErrorGivenErrorThenCallsErrorDelegate() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.received(error: NSError(), forURL: URL(string: "www.example.com")!)

        XCTAssertEqual(engineSessionDelegate.onErrorPageCalled, 1)
    }

    // MARK: User script manager

    func testUserScriptWhenSubjectCreatedThenInjectionIntoWebviewCalled() {
        _ = createSubject()
        XCTAssertEqual(userScriptManager.injectUserScriptsIntoWebViewCalled, 1)
    }

    // MARK: Content script manager

    func testContentScriptGivenInitContentScriptsThenAreAddedAtInit() {
        _ = createSubject()

        XCTAssertEqual(contentScriptManager.addContentScriptCalled, 2)
        XCTAssertEqual(contentScriptManager.savedContentScriptNames.count, 2)
        XCTAssertEqual(contentScriptManager.savedContentScriptNames[0], FindInPageContentScript.name())
        XCTAssertEqual(contentScriptManager.savedContentScriptNames[1], AdsTelemetryContentScript.name())
    }

    func testContentScriptWhenCloseCalledThenUninstallIsCalled() {
        let subject = createSubject()

        subject?.close()

        XCTAssertEqual(contentScriptManager.uninstallCalled, 1)
    }

    // MARK: WKEngineWebViewDelegate

    func testFindInPageGivenSelectionThenCallsDelegate() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        let expectedSelection = "A search"

        subject?.tabWebView(webViewProvider.webView, findInPageSelection: expectedSelection)

        XCTAssertEqual(engineSessionDelegate.findInPageCalled, 1)
        XCTAssertEqual(engineSessionDelegate.savedFindInPageSelection, expectedSelection)
    }

    func testSearchGivenSelectionThenCallsDelegate() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        let expectedSelection = "Find in page"

        subject?.tabWebView(webViewProvider.webView, searchSelection: expectedSelection)

        XCTAssertEqual(engineSessionDelegate.searchCalled, 1)
        XCTAssertEqual(engineSessionDelegate.savedSearchSelection, expectedSelection)
    }

    // MARK: Helper

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> WKEngineSession? {
        guard let subject = WKEngineSession(userScriptManager: userScriptManager,
                                            configurationProvider: configurationProvider,
                                            webViewProvider: webViewProvider,
                                            contentScriptManager: contentScriptManager,
                                            metadataFetcher: metadataFetcher) else {
            return nil
        }

        trackForMemoryLeaks(subject, file: file, line: line)

        // Each registered teardown block is run once, in last-in, first-out order, executed serially.
        // Order is important here since the close() function needs to be called before we check for leaks
        addTeardownBlock { [weak subject] in
            subject?.close()
        }

        return subject
    }
}
