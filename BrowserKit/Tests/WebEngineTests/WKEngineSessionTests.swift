// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine
import WebKit

@available(iOS 16.0, *)
final class WKEngineSessionTests: XCTestCase {
    private var configurationProvider: MockWKEngineConfigurationProvider!
    private var webViewProvider: MockWKWebViewProvider!
    private var contentScriptManager: MockWKContentScriptManager!
    private var userScriptManager: MockWKUserScriptManager!
    private var engineSessionDelegate: MockEngineSessionDelegate!
    private var metadataFetcher: MockMetadataFetcherHelper!

    override func setUp() {
        super.setUp()
        configurationProvider = MockWKEngineConfigurationProvider()
        webViewProvider = MockWKWebViewProvider()
        contentScriptManager = MockWKContentScriptManager()
        userScriptManager = MockWKUserScriptManager()
        engineSessionDelegate = MockEngineSessionDelegate()
        metadataFetcher = MockMetadataFetcherHelper()
    }

    override func tearDown() {
        super.tearDown()
        configurationProvider = nil
        webViewProvider = nil
        contentScriptManager = nil
        userScriptManager = nil
        engineSessionDelegate = nil
        metadataFetcher = nil
    }

    // MARK: Load URL

    func testLoadURLGivenNormalURLThenLoad() {
        let subject = createSubject()
        let url = URL(string: "https://example.com")!
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let browserURL = BrowserURL(browsingContext: context)!

        subject?.load(browserURL: browserURL)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url, url)
    }

    func testLoadURLGivenReaderModeURLThenLoad() {
        let subject = createSubject()
        let url = URL(string: "about:reader?url=http://example.com")!
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let browserURL = BrowserURL(browsingContext: context)!

        subject?.load(browserURL: browserURL)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString,
                       "http://localhost:0/reader-mode/page?url=http%3A%2F%2Fexample%2Ecom")
    }

    func testLoadURLGivenFileURLThenLoadFileURL() {
        let subject = createSubject()
        let url = URL(string: "file://path/to/abc/dirA/A.html")!
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let browserURL = BrowserURL(browsingContext: context)!

        subject?.load(browserURL: browserURL)

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

    func testShowFindInPageThenPresentNavigatorCalled() {
        let subject = createSubject()

        subject?.showFindInPage()

        XCTAssertTrue(webViewProvider.webView.isFindInteractionEnabled)
        XCTAssertNil(webViewProvider.webView.findInteraction)
    }

    func testShowFindInPageGivenSearchTextThenPresentNavigatorCalled() {
        let searchText = "SearchTerm"
        let findInteraction = MockUIFindInteraction()
        let subject = createSubject()
        webViewProvider.webView.findInteraction = findInteraction

        subject?.showFindInPage(withSearchText: searchText)

        XCTAssertTrue(webViewProvider.webView.isFindInteractionEnabled)
        XCTAssertNotNil(webViewProvider.webView.findInteraction)
        XCTAssertEqual(findInteraction.presentFindNavigatorCalled, 1)
        XCTAssertEqual(findInteraction.searchText, searchText)
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
        let internalURL = URL(string: "internal://local/errorpage?url=\(errorPageURL)")!
        let context = BrowsingContext(type: .internalNavigation, url: internalURL)
        let browserURL = BrowserURL(browsingContext: context)!
        subject?.load(browserURL: browserURL)

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, errorPageURL)
    }

    func testReloadWhenHomepageThenLoadHomepageAsPrivileged() throws {
        let subject = createSubject()
        let internalURL = URL(string: "internal://local/about/home")!
        let context = BrowsingContext(type: .internalNavigation, url: internalURL)
        let browserURL = BrowserURL(browsingContext: context)!
        subject?.load(browserURL: browserURL)

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2)
        let url = try XCTUnwrap(webViewProvider.webView.url)
        XCTAssertTrue(url.absoluteString.contains("internal://local/about/home?uuidkey="))
    }

    func testReloadWhenBypassCacheThenReloadBypassingCache() {
        let subject = createSubject()
        let url = URL(string: "https://www.example.com")!
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let browserURL = BrowserURL(browsingContext: context)!
        subject?.load(browserURL: browserURL)

        subject?.reload(bypassCache: true)

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2)
        XCTAssertEqual(webViewProvider.webView.url, url)
    }

    func testReloadWhenReloadFromOriginFailsThenRestoreWebviewWithLastRequest() {
        let subject = createSubject()
        let url = URL(string: "https://www.example.com")!
        let context = BrowsingContext(type: .internalNavigation, url: url)
        let browserURL = BrowserURL(browsingContext: context)!
        subject?.load(browserURL: browserURL)

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 1)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2)
        XCTAssertEqual(webViewProvider.webView.url, url)
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
        let context = BrowsingContext(type: .internalNavigation, url: URL(string: "https://example.com")!)
        let browserURL = BrowserURL(browsingContext: context)!
        subject?.load(browserURL: browserURL)

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
        let canGoBack = true
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.canGoBack = canGoBack
        webViewProvider.webView.canGoForward = false

        subject?.observeValue(forKeyPath: "canGoBack",
                              of: nil,
                              change: [NSKeyValueChangeKey.newKey: canGoBack],
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onNavigationStateChangeCalled, 1)
        XCTAssertTrue(engineSessionDelegate.savedCanGoBack!)
        XCTAssertFalse(engineSessionDelegate.savedCanGoForward!)
    }

    func testCanGoBackGivenNoObserveValueChangeThenCallsNothing() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.observeValue(forKeyPath: "canGoBack",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onNavigationStateChangeCalled, 0)
        XCTAssertNil(engineSessionDelegate.savedCanGoBack)
        XCTAssertNil(engineSessionDelegate.savedCanGoForward)
    }

    func testCanGoForwardGivenWebviewStateThenCallsNavigationStateChanged() {
        let canGoForward = true
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.canGoBack = false
        webViewProvider.webView.canGoForward = canGoForward

        subject?.observeValue(forKeyPath: "canGoForward",
                              of: nil,
                              change: [NSKeyValueChangeKey.newKey: canGoForward],
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onNavigationStateChangeCalled, 1)
        XCTAssertFalse(engineSessionDelegate.savedCanGoBack!)
        XCTAssertTrue(engineSessionDelegate.savedCanGoForward!)
    }

    func testCanGoForwardGivenNoObserveValueChangeThenCallsNothing() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.observeValue(forKeyPath: "canGoForward",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onNavigationStateChangeCalled, 0)
        XCTAssertNil(engineSessionDelegate.savedCanGoBack)
        XCTAssertNil(engineSessionDelegate.savedCanGoForward)
    }

    func testEstimatedProgressGivenWebviewStateThenCallsOnProgress() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.url = URL(string: "www.mozilla.com")!
        webViewProvider.webView.estimatedProgress = 70

        subject?.observeValue(forKeyPath: "estimatedProgress",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onProgressCalled, 1)
        XCTAssertEqual(engineSessionDelegate.savedProgressValue, 70)
    }

    func testEstimatedProgressGivenNoURLThenCallsOnHideProgressBar() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.observeValue(forKeyPath: "estimatedProgress",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onHideProgressCalled, 1)
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

    func testLoadingGivenIsLoadingThenCallsRefreshControlBegin() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        let refreshControl = MockUIRefreshControl()
        webViewProvider.webView.engineScrollView?.refreshControl = refreshControl

        subject?.observeValue(forKeyPath: "loading",
                              of: nil,
                              change: [.newKey: true],
                              context: nil)

        XCTAssertEqual(refreshControl.beginRefreshingCalled, 1)
        XCTAssertEqual(refreshControl.endRefreshingCalled, 0)
    }

    func testLoadingGivenIsNotLoadingThenCallsRefreshControlEnd() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        let refreshControl = MockUIRefreshControl()
        webViewProvider.webView.engineScrollView?.refreshControl = refreshControl

        subject?.observeValue(forKeyPath: "loading",
                              of: nil,
                              change: [.newKey: false],
                              context: nil)

        XCTAssertEqual(refreshControl.beginRefreshingCalled, 0)
        XCTAssertEqual(refreshControl.endRefreshingCalled, 1)
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

    func testURLChangeGivenNotAuthorizedErrorPageThenLoadsAboutBlank() {
        let internalURL = URL(string: "internal://local/errorpage?url=errorPage")!
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.url = internalURL

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(subject?.sessionData.url, nil)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url, URL(string: "about:blank")!)
    }

    func testHadOnlySecureContentGivenSecureContentThenSavesAndCallsDelegate() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        webViewProvider.webView.hasOnlySecureContent = true

        subject?.observeValue(forKeyPath: "hasOnlySecureContent",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(subject?.sessionData.hasOnlySecureContent, true)
        XCTAssertEqual(engineSessionDelegate.onHasOnlySecureContentCalled, 1)
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

        XCTAssertEqual(contentScriptManager.addContentScriptCalled, 1)
        XCTAssertEqual(contentScriptManager.savedContentScriptNames.count, 1)
        XCTAssertEqual(contentScriptManager.savedContentScriptNames[0], AdsTelemetryContentScript.name())
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
