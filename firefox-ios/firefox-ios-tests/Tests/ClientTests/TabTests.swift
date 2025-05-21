// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared
@testable import Client

class TabTests: XCTestCase {
    var mockProfile: MockProfile!
    private var tabDelegate: MockLegacyTabDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var fileManager: MockFileManager!
    private var mockTabWebView: MockTabWebView!
    private var dispatchQueue: MockDispatchQueue!
    private let url = URL(string: "file://test.pdf")!

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        mockTabWebView = MockTabWebView(frame: .zero, configuration: .init(), windowUUID: windowUUID)
        mockTabWebView.loadedURL = url
        fileManager = MockFileManager()
        dispatchQueue = MockDispatchQueue()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        DependencyHelperMock().bootstrapDependencies()

        // Disable debug flag for faster inactive tabs and perform tests based on the real 14 day time to inactive
        UserDefaults.standard.set(nil, forKey: PrefsKeys.FasterInactiveTabsOverride)
    }

    override func tearDown() {
        tabDelegate = nil
        mockProfile = nil
        mockTabWebView = nil
        fileManager = nil
        dispatchQueue = nil
        setIsPDFRefactorFeature(isEnabled: false)
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testShareURL_RemovingReaderModeComponents() {
        let url = URL(string: "http://localhost:123/reader-mode/page?url=https://mozilla.org")!

        guard let newUrl = url.displayURL else {
            XCTFail("expected valid url without reader mode components")
            return
        }

        XCTAssertEqual(newUrl.host, "mozilla.org")
    }

    func testDisplayTitle_ForHomepageURL() {
        let url = URL(string: "internal://local/about/home")!
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        tab.url = url
        let expectedDisplayTitle = String.LegacyAppMenu.AppMenuOpenHomePageTitleString
        XCTAssertEqual(tab.displayTitle, expectedDisplayTitle)
    }

    func testTitle_WhenWebViewTitleIsNil_ThenShouldReturnNil() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        tab.webView = mockTabWebView
        mockTabWebView.mockTitle = nil
        XCTAssertNil(tab.title, "Expected title to be nil when webView.title is nil")
    }

    func testTitle_WhenWebViewTitleIsEmpty_ThenShouldReturnNil() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        tab.webView = mockTabWebView
        mockTabWebView.mockTitle = ""
        XCTAssertNil(tab.title, "Expected title to be nil when webView.title is empty")
    }

    func testTitle_WhenWebViewTitleIsValid_ThenShouldReturnTitle() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        tab.webView = mockTabWebView
        mockTabWebView.mockTitle = "Test Page Title"
        XCTAssertEqual(tab.title, "Test Page Title", "Expected title to return the webView's title")
    }

    func testTabDoesntLeak() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        tab.tabDelegate = tabDelegate
        trackForMemoryLeaks(tab)
    }

    func testIsDownloadingDocument_whenDocumentIsNil_returnsFalse() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)

        XCTAssertFalse(tab.isDownloadingDocument())
    }

    func testIsDownloadingDocument_whenDocumentIsDownloading_returnsTrue() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let document = MockTemporaryDocument(withFileURL: URL(string: "https://www.example.com")!)
        document.isDownloading = true

        tab.enqueueDocument(document)

        XCTAssertTrue(tab.isDownloadingDocument())
    }

    // MARK: - isActive, isInactive

    func testTabIsActive_within14Days() {
        // Tabs use the current date by default, so this one should be considered recent and active on initialization
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)

        XCTAssertTrue(tab.isActive)
        XCTAssertFalse(tab.isInactive)
    }

    func testTabIsInactive_outside14Days() {
        let lastMonthDate = Date().lastMonth
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID, tabCreatedTime: lastMonthDate)

        XCTAssertFalse(tab.isActive)
        XCTAssertTrue(tab.isInactive)
    }

    // MARK: - isSameTypeAs

    func testIsSameTypeAs_trueForTwoPrivateTabs_oneActive_oneInactive() {
        let lastMonthDate = Date().lastMonth

        let privateActiveTab = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID
        )
        let privateInactiveTab = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // We do not want to differentiate between inactive and active for private tabs. They are all grouped together.
        XCTAssertTrue(privateActiveTab.isSameTypeAs(privateInactiveTab))
        XCTAssertTrue(privateInactiveTab.isSameTypeAs(privateActiveTab))
    }

    func testIsSameTypeAs_trueForTwoPrivateTabs_bothActive() {
        let privateActiveTab1 = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID
        )
        let privateActiveTab2 = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID
        )

        XCTAssertTrue(privateActiveTab1.isSameTypeAs(privateActiveTab2))
        XCTAssertTrue(privateActiveTab2.isSameTypeAs(privateActiveTab1))
    }

    func testIsSameTypeAs_trueForTwoPrivateTabs_bothInactive() {
        let lastMonthDate = Date().lastMonth

        let privateInactiveTab1 = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )
        let privateInactiveTab2 = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        XCTAssertTrue(privateInactiveTab1.isSameTypeAs(privateInactiveTab2))
        XCTAssertTrue(privateInactiveTab2.isSameTypeAs(privateInactiveTab1))
    }

    func testIsSameTypeAs_falseForNormalTabAndPrivateTab() {
        let lastMonthDate = Date().lastMonth

        let privateTab = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID
        )
        let normalActiveTab = Tab(
            profile: mockProfile,
            windowUUID: windowUUID
        )
        let normalInactiveTab = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // A normal tab and a private tab should never be the same, regardless of the normal tab's inactive/active state.
        XCTAssertFalse(privateTab.isSameTypeAs(normalActiveTab))
        XCTAssertFalse(privateTab.isSameTypeAs(normalInactiveTab))
        XCTAssertFalse(normalActiveTab.isSameTypeAs(privateTab))
        XCTAssertFalse(normalInactiveTab.isSameTypeAs(privateTab))
    }

    func testIsSameTypeAs_falseForNormalActiveTab_andNormalInactiveTab() {
        let lastMonthDate = Date().lastMonth

        let normalActiveTab = Tab(
            profile: mockProfile,
            windowUUID: windowUUID
        )
        let normalInactiveTab = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // In the app, a normal active tab is a different type of tab than a normal inactive tab.
        XCTAssertFalse(normalActiveTab.isSameTypeAs(normalInactiveTab))
        XCTAssertFalse(normalInactiveTab.isSameTypeAs(normalActiveTab))
    }

    func testIsSameTypeAs_trueForTwoNormalTabs_bothActive() {
        let normalActiveTab1 = Tab(
            profile: mockProfile,
            windowUUID: windowUUID
        )
        let normalActiveTab2 = Tab(
            profile: mockProfile,
            windowUUID: windowUUID
        )

        XCTAssertTrue(normalActiveTab1.isSameTypeAs(normalActiveTab2))
        XCTAssertTrue(normalActiveTab2.isSameTypeAs(normalActiveTab1))
    }

    func testIsSameTypeAs_trueForTwoNormalTabs_bothInactive() {
        let lastMonthDate = Date().lastMonth

        let normalInactiveTab1 = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )
        let normalInactiveTab2 = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        XCTAssertTrue(normalInactiveTab1.isSameTypeAs(normalInactiveTab2))
        XCTAssertTrue(normalInactiveTab2.isSameTypeAs(normalInactiveTab1))
    }

    // MARK: - Document Handling

    func testEnqueueDocument() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        subject.enqueueDocument(document)

        XCTAssertEqual(document.downloadCalled, 1)
        XCTAssertNotNil(subject.temporaryDocument)
    }

    func testLoadDocumentRequest() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url, request: URLRequest(url: url))

        subject.enqueueDocument(document)

        XCTAssertFalse(subject.shouldDownloadDocument(URLRequest(url: url)))
        XCTAssertNotNil(subject.temporaryDocument)
    }

    func testReload_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        setIsPDFRefactorFeature(isEnabled: true)
        document.isDownloading = true
        subject.webView = mockTabWebView
        subject.enqueueDocument(document)

        subject.reload()
        subject.webView = nil

        XCTAssertNil(subject.temporaryDocument)
        XCTAssertEqual(mockTabWebView.loadFileURLCalled, 1)
        XCTAssertEqual(mockTabWebView.reloadFromOriginCalled, 1)
    }

    func testGoBack_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        setIsPDFRefactorFeature(isEnabled: true)
        subject.webView = mockTabWebView
        subject.url = url
        document.isDownloading = true
        subject.enqueueDocument(document)

        subject.goBack()
        // remove it so in Tab deinit there is no crash for KVO
        subject.webView = nil

        XCTAssertNil(subject.temporaryDocument)
        XCTAssertEqual(mockTabWebView.loadFileURLCalled, 1)
        XCTAssertEqual(mockTabWebView.reloadFromOriginCalled, 1)
        // it doesn't go back while cancelling a document
        XCTAssertEqual(mockTabWebView.goBackCalled, 0)
    }

    func testGoForward_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        setIsPDFRefactorFeature(isEnabled: true)
        subject.webView = mockTabWebView
        document.isDownloading = true
        subject.enqueueDocument(document)

        subject.goForward()
        // remove it so in Tab deinit there is no crash for KVO
        subject.webView = nil

        XCTAssertNil(subject.temporaryDocument)
        XCTAssertEqual(mockTabWebView.loadFileURLCalled, 1)
        XCTAssertEqual(mockTabWebView.reloadFromOriginCalled, 1)
        // it doesn't go forward while cancelling a document
        XCTAssertEqual(mockTabWebView.goForwardCalled, 0)
    }

    func testLoadRequest_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        setIsPDFRefactorFeature(isEnabled: true)
        subject.webView = mockTabWebView
        document.isDownloading = true
        subject.enqueueDocument(document)

        subject.loadRequest(URLRequest(url: url))
        // remove it so in Tab deinit there is no crash for KVO
        subject.webView = nil

        XCTAssertNil(subject.temporaryDocument)

        XCTAssertEqual(
            mockTabWebView.loadFileURLCalled,
            1,
            "enqueue document should call load file url on webView"
        )
        XCTAssertEqual(
            mockTabWebView.loadCalled,
            1,
            "load request should call load on webView"
        )
        XCTAssertEqual(mockTabWebView.reloadFromOriginCalled, 0)
    }

    func testStop_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        setIsPDFRefactorFeature(isEnabled: true)
        subject.webView = mockTabWebView
        document.isDownloading = true

        subject.enqueueDocument(document)
        subject.stop()
        subject.webView = nil

        XCTAssertEqual(mockTabWebView.loadFileURLCalled, 1)
        XCTAssertEqual(mockTabWebView.stopLoadingCalled, 1)
        XCTAssertEqual(mockTabWebView.reloadFromOriginCalled, 1)
    }

    func testSetURL_showsOnlineURLForLocalDocument_whenPDFRefactorEnabled() {
        let subject = createSubject()
        let request = URLRequest(url: URL(string: "https://www.example.com")!)
        let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.pdf")
        let document = MockTemporaryDocument(withFileURL: localURL, request: request)

        setIsPDFRefactorFeature(isEnabled: true)
        subject.enqueueDocument(document)

        subject.url = localURL

        XCTAssertEqual(subject.url, request.url)
    }

    func testPauseDocumentDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument()

        subject.enqueueDocument(document)
        subject.pauseDocumentDownload()

        XCTAssertEqual(document.pauseDownloadCalled, 1)
    }

    func testResumeDocumentDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument()

        subject.enqueueDocument(document)
        subject.resumeDocumentDownload()

        XCTAssertEqual(document.resumeDownloadCalled, 1)
    }

    func testCancelDocumentDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument()

        subject.enqueueDocument(document)
        subject.cancelDocumentDownload()

        XCTAssertEqual(document.cancelDownloadCalled, 1)
    }

    func testShouldDownloadDocument_whenDocumentInSession_addsTemporaryDocument() {
        let subject = createSubject()

        let localPDFUrl = URL(string: "file://test.pdf")!
        let onlinePDFUrl = URL(string: "https://example.com/test.pdf")!

        fileManager.fileExists = false
        subject.restoreTemporaryDocumentSession([localPDFUrl: onlinePDFUrl])

        let result = subject.shouldDownloadDocument(URLRequest(url: localPDFUrl))

        XCTAssertNotNil(subject.temporaryDocument)
        XCTAssertTrue(result, "result should be the opposite fileManager.fileExists")
    }

    func testShouldDownloadDocument_whenDocumentNotInSession_returnsTrueForNilTemporaryDocument() {
        let subject = createSubject()

        let localPDFUrl = URL(string: "file://test.pdf")!

        let result = subject.shouldDownloadDocument(URLRequest(url: localPDFUrl))

        XCTAssertNil(subject.temporaryDocument)
        XCTAssertTrue(result)
    }

    func testShouldDownloadDocument_whenDocumentNotInSession_forwardRequestToTemporaryDocument() {
        let subject = createSubject()
        let document = MockTemporaryDocument()
        subject.temporaryDocument = document

        let localPDFUrl = URL(string: "file://test.pdf")!

        _ = subject.shouldDownloadDocument(URLRequest(url: localPDFUrl))

        XCTAssertEqual(document.canDownloadCalled, 1)
    }

    func testDeinit_removesAllDocumentInSession() {
        var subject: Tab? = createSubject()
        let session = [
            URL(string: "file://local.pdf")!: URL(string: "https://www.example.com")!
        ]
        subject?.restoreTemporaryDocumentSession(session)

        // deallocate object
        subject = nil

        XCTAssertEqual(dispatchQueue.asyncCalled, 1)
        XCTAssertEqual(fileManager.removeItemAtURLCalled, 1)
    }

    // MARK: - Helpers
    private func createSubject() -> Tab {
        let subject = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            backgroundDispatchQueue: dispatchQueue,
            fileManager: fileManager
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setIsPDFRefactorFeature(isEnabled: Bool) {
        FxNimbus.shared.features.pdfRefactorFeature.with { _, _ in
            PdfRefactorFeature(enabled: isEnabled)
        }
    }
}

// MARK: - MockLegacyTabDelegate
class MockLegacyTabDelegate: LegacyTabDelegate {
    func tab(_ tab: Tab, didAddLoginAlert alert: SaveLoginAlert) {}

    func tab(_ tab: Tab, didRemoveLoginAlert alert: SaveLoginAlert) {}

    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String) {}

    func tab(_ tab: Tab, didSelectSearchWithFirefoxForSelection selection: String) {}

    func tab(_ tab: Tab, didCreateWebView webView: WKWebView) {}

    func tab(_ tab: Tab, willDeleteWebView webView: WKWebView) {}
}
