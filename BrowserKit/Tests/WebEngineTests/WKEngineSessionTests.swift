// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class WKEngineSessionTests: XCTestCase {
    private var configurationProvider: MockWKEngineConfigurationProvider!
    private var webViewProvider: MockWKWebViewProvider!
    private var contentScriptManager: MockWKContentScriptManager!
    private var userScriptManager: MockWKUserScriptManager!
    private var engineSessionDelegate: MockEngineSessionDelegate!

    override func setUp() {
        super.setUp()
        configurationProvider = MockWKEngineConfigurationProvider()
        webViewProvider = MockWKWebViewProvider()
        contentScriptManager = MockWKContentScriptManager()
        userScriptManager = MockWKUserScriptManager()
        engineSessionDelegate = MockEngineSessionDelegate()
    }

    override func tearDown() {
        super.tearDown()
        configurationProvider = nil
        webViewProvider = nil
        contentScriptManager = nil
        userScriptManager = nil
        engineSessionDelegate = nil
    }

    // MARK: Load URL

    func testLoadURLGivenEmptyThenDoesntLoad() {
        let subject = createSubject()
        let url = ""

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
        prepareForTearDown(subject!)
    }

    func testLoadURLGivenNotAURLThenDoesntLoad() {
        let subject = createSubject()
        let url = "blablablablabla"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
        prepareForTearDown(subject!)
    }

    func testLoadURLGivenNormalURLThenLoad() {
        let subject = createSubject()
        let url = "https://example.com"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, url)
        prepareForTearDown(subject!)
    }

    func testLoadURLGivenReaderModeURLThenLoad() {
        let subject = createSubject()
        let url = "about:reader?url=http://example.com"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString,
                       "http://localhost:0/reader-mode/page?url=http%3A%2F%2Fexample%2Ecom")
        prepareForTearDown(subject!)
    }

    func testLoadURLGivenFileURLThenLoadFileURL() {
        let subject = createSubject()
        let url = "file://path/to/abc/dirA/A.html"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadFileURLCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, "file://path/to/abc/dirA/A.html")
        XCTAssertEqual(webViewProvider.webView.loadFileReadAccessURL?.absoluteString, "file://path/to/abc/dirA/")
        prepareForTearDown(subject!)
    }

    // MARK: Stop URL

    func testStopLoading() {
        let subject = createSubject()

        subject?.stopLoading()

        XCTAssertEqual(webViewProvider.webView.stopLoadingCalled, 1)
        prepareForTearDown(subject!)
    }

    // MARK: Go back

    func testGoBack() {
        let subject = createSubject()

        subject?.goBack()

        XCTAssertEqual(webViewProvider.webView.goBackCalled, 1)
        prepareForTearDown(subject!)
    }

    // MARK: Go forward

    func testGoForward() {
        let subject = createSubject()

        subject?.goForward()

        XCTAssertEqual(webViewProvider.webView.goForwardCalled, 1)
        prepareForTearDown(subject!)
    }

    // MARK: Scroll to top

    func testScrollToTop() {
        let subject = createSubject()

        subject?.scrollToTop()

        let scrollView = webViewProvider.webView.engineScrollView as? MockEngineScrollView
        XCTAssertEqual(scrollView?.setContentOffsetCalled, 1)
        XCTAssertEqual(scrollView?.savedContentOffset, CGPoint.zero)
        prepareForTearDown(subject!)
    }

    // MARK: Reload

    func testReloadThenCallsReloadFromOrigin() {
        let subject = createSubject()

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 1)
        prepareForTearDown(subject!)
    }

    func testReloadWhenErrorPageThenReplaceLocation() {
        let subject = createSubject()
        let errorPageURL = "errorpage"
        let internalURL = "internal://local/errorpage?url=\(errorPageURL)"
        subject?.load(url: internalURL)

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 0)
        XCTAssertEqual(webViewProvider.webView.replaceLocationCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, errorPageURL)
        prepareForTearDown(subject!)
    }

    // MARK: Restore

    func testRestoreWhenNoLastRequestThenLoadNotCalled() {
        let subject = createSubject()
        let restoredState = Data()

        subject?.restore(state: restoredState)

        XCTAssertEqual(webViewProvider.webView.interactionState as! Data, restoredState)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
        prepareForTearDown(subject!)
    }

    func testRestoreWhenHasLastRequestThenLoadISCalled() {
        let subject = createSubject()
        let restoredState = Data()
        subject?.load(url: "https://example.com")

        subject?.restore(state: restoredState)

        XCTAssertEqual(webViewProvider.webView.interactionState as! Data, restoredState)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2, "Load calls it once, then restore calls it again")
        prepareForTearDown(subject!)
    }

    // MARK: Observers

    func testAddObserversWhenCreatedSubjectThenObserversAreAdded() {
        let subject = createSubject()
        XCTAssertEqual(webViewProvider.webView.addObserverCalled, 7, "There are 7 KVO Constants")
        prepareForTearDown(subject!)
    }

    func testRemoveObserversWhenCloseIsCalledThenObserversAreRemoved() {
        let subject = createSubject()

        subject?.close()

        XCTAssertEqual(webViewProvider.webView.removeObserverCalled, 7, "There are 7 KVO Constants")
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
    }

    func testLoadingGivenNoChangeThenDoesNotCallOnLoadingStateChange() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.observeValue(forKeyPath: "loading",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
        prepareForTearDown(subject!)
    }

    func testLoadingGivenOldKeyThenDoesNotCallOnLoadingStateChange() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate

        subject?.observeValue(forKeyPath: "loading",
                              of: nil,
                              change: [.oldKey: true],
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
    }

    func testURLChangeGivenNilURLThenDoesntCallDelegate() {
        let subject = createSubject()
        webViewProvider.webView.title = nil

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertNil(subject?.sessionData.url)
        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
        prepareForTearDown(subject!)
    }

    func testURLChangeGivenAboutBlankWithNilURLThenDoesntCallDelegate() {
        let subject = createSubject()
        subject?.sessionData.url = URL(string: "about:blank")!
        webViewProvider.webView.title = nil

        subject?.observeValue(forKeyPath: "URL",
                              of: nil,
                              change: nil,
                              context: nil)

        XCTAssertEqual(engineSessionDelegate.onLoadingStateChangeCalled, 0)
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
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
        prepareForTearDown(subject!)
    }

    // MARK: User script manager

    func testUserScriptWhenSubjectCreatedThenInjectionIntoWebviewCalled() {
        let subject = createSubject()
        XCTAssertEqual(userScriptManager.injectUserScriptsIntoWebViewCalled, 1)
        prepareForTearDown(subject!)
    }

    // MARK: Content script manager

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
        prepareForTearDown(subject!)
    }

    func testSearchGivenSelectionThenCallsDelegate() {
        let subject = createSubject()
        subject?.delegate = engineSessionDelegate
        let expectedSelection = "Find in page"

        subject?.tabWebView(webViewProvider.webView, searchSelection: expectedSelection)

        XCTAssertEqual(engineSessionDelegate.searchCalled, 1)
        XCTAssertEqual(engineSessionDelegate.savedSearchSelection, expectedSelection)
        prepareForTearDown(subject!)
    }

    // MARK: Helper

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> WKEngineSession? {
        guard let subject = WKEngineSession(userScriptManager: userScriptManager,
                                            configurationProvider: configurationProvider,
                                            webViewProvider: webViewProvider,
                                            contentScriptManager: contentScriptManager) else {
            return nil
        }

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    // Adding a special teardown since as part of tracking memory leaks, we can't use an instance variable on the
    // test suite. A normal instance `tearDown` is called after a `addTeardownBlock`. To ensure we still can
    // `trackForMemoryLeaks` we need to always close any engine session that is opened, otherwise leaks happens.
    func prepareForTearDown(_ subject: WKEngineSession) {
        subject.close()
    }
}
