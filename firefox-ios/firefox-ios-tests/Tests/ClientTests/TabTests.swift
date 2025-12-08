// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared
@testable import Client

@MainActor
class TabTests: XCTestCase {
    var mockProfile: MockProfile!
    private var tabDelegate: MockLegacyTabDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var mockFileManager: MockFileManager!
    private var mockTabWebView: MockTabWebView!
    private let url = URL(string: "file://test.pdf")!
    private var mockDispatchQueue: MockDispatchQueue!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        mockTabWebView = MockTabWebView(frame: .zero, configuration: .init(), windowUUID: windowUUID)
        mockTabWebView.loadedURL = url
        mockFileManager = MockFileManager()
        mockDispatchQueue = MockDispatchQueue()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        tabDelegate = nil
        mockProfile = nil
        mockTabWebView = nil
        mockFileManager = nil
        mockDispatchQueue = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testShareURL_RemovingReaderModeComponents() {
        let url = URL(string: "http://localhost:123/reader-mode/page?url=https://mozilla.org")!

        guard let newUrl = url.displayURL else {
            XCTFail("expected valid url without reader mode components")
            return
        }

        XCTAssertEqual(newUrl.host, "mozilla.org")
    }

    @MainActor
    func testDisplayTitle_ForHomepageURL() {
        let url = URL(string: "internal://local/about/home")!
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        tab.url = url
        let expectedDisplayTitle = String.LegacyAppMenu.AppMenuOpenHomePageTitleString
        XCTAssertEqual(tab.displayTitle, expectedDisplayTitle)
    }

    @MainActor
    func testTitle_WhenWebViewTitleIsNil_ThenShouldReturnNil() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        tab.webView = mockTabWebView
        mockTabWebView.mockTitle = nil
        XCTAssertNil(tab.title, "Expected title to be nil when webView.title is nil")
    }

    @MainActor
    func testTitle_WhenWebViewTitleIsEmpty_ThenShouldReturnNil() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        tab.webView = mockTabWebView
        mockTabWebView.mockTitle = ""
        XCTAssertNil(tab.title, "Expected title to be nil when webView.title is empty")
    }

    @MainActor
    func testTitle_WhenWebViewTitleIsValid_ThenShouldReturnTitle() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        tab.webView = mockTabWebView
        mockTabWebView.mockTitle = "Test Page Title"
        XCTAssertEqual(tab.title, "Test Page Title", "Expected title to return the webView's title")
    }

    @MainActor
    func testTabDoesntLeak() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        tab.tabDelegate = tabDelegate
        trackForMemoryLeaks(tab)
    }

    @MainActor
    func testIsDownloadingDocument_whenDocumentIsNil_returnsFalse() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)

        XCTAssertFalse(tab.isDownloadingDocument())
    }

    @MainActor
    func testIsDownloadingDocument_whenDocumentIsDownloading_returnsTrue() {
        let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let document = MockTemporaryDocument(withFileURL: URL(string: "https://www.example.com")!)
        document.isDownloading = true

        tab.enqueueDocument(document)

        XCTAssertTrue(tab.isDownloadingDocument())
    }

    // MARK: - isSameTypeAs
    @MainActor
    func testIsSameTypeAs_trueForTwoPrivateTabs_oneNormal_oneOlder() {
        let lastMonthDate = Date().lastMonth

        let privateTab = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID
        )
        let privateOlderTab = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // We do not want to differentiate between older and normal for private tabs. They are all grouped together.
        XCTAssertTrue(privateTab.isSameTypeAs(privateOlderTab))
        XCTAssertTrue(privateOlderTab.isSameTypeAs(privateTab))
    }

    @MainActor
    func testIsSameTypeAs_trueForTwoPrivateTabs_bothNormal() {
        let privateTab1 = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID
        )
        let privateTab2 = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID
        )

        XCTAssertTrue(privateTab1.isSameTypeAs(privateTab2))
        XCTAssertTrue(privateTab2.isSameTypeAs(privateTab1))
    }

    @MainActor
    func testIsSameTypeAs_trueForTwoPrivateTabs_bothOlder() {
        let lastMonthDate = Date().lastMonth

        let privateOlderTab1 = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )
        let privateOlderTab2 = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        XCTAssertTrue(privateOlderTab1.isSameTypeAs(privateOlderTab2))
        XCTAssertTrue(privateOlderTab2.isSameTypeAs(privateOlderTab1))
    }

    @MainActor
    func testIsSameTypeAs_falseForNormalTabAndPrivateTab() {
        let lastMonthDate = Date().lastMonth

        let privateTab = Tab(
            profile: mockProfile,
            isPrivate: true,
            windowUUID: windowUUID
        )
        let normalTab = Tab(
            profile: mockProfile,
            windowUUID: windowUUID
        )
        let normalOlderTab = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // A normal tab and a private tab should never be the same.
        XCTAssertFalse(privateTab.isSameTypeAs(normalTab))
        XCTAssertFalse(privateTab.isSameTypeAs(normalOlderTab))
        XCTAssertFalse(normalTab.isSameTypeAs(privateTab))
        XCTAssertFalse(normalOlderTab.isSameTypeAs(privateTab))
    }

    @MainActor
    func testIsSameTypeAs_trueForNormalTab_andNormalOlderTab() {
        let lastMonthDate = Date().lastMonth

        let normalTab = Tab(
            profile: mockProfile,
            windowUUID: windowUUID
        )
        let normalOlderTab = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // In the app, a normal tab is the same type of tab than a normal older tab.
        XCTAssertTrue(normalTab.isSameTypeAs(normalOlderTab))
        XCTAssertTrue(normalOlderTab.isSameTypeAs(normalTab))
    }

    @MainActor
    func testIsSameTypeAs_trueForTwoNormalTabs_bothNormal() {
        let normalTab1 = Tab(
            profile: mockProfile,
            windowUUID: windowUUID
        )
        let normalTab2 = Tab(
            profile: mockProfile,
            windowUUID: windowUUID
        )

        XCTAssertTrue(normalTab1.isSameTypeAs(normalTab2))
        XCTAssertTrue(normalTab2.isSameTypeAs(normalTab1))
    }

    @MainActor
    func testIsSameTypeAs_trueForTwoNormalTabs_bothOlder() {
        let lastMonthDate = Date().lastMonth

        let normalOlderTab1 = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )
        let normalOlderTab2 = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        XCTAssertTrue(normalOlderTab1.isSameTypeAs(normalOlderTab2))
        XCTAssertTrue(normalOlderTab2.isSameTypeAs(normalOlderTab1))
    }

    // MARK: - Document Handling
    @MainActor
    func testEnqueueDocument() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        subject.enqueueDocument(document)

        XCTAssertEqual(document.downloadCalled, 1)
        XCTAssertNotNil(subject.temporaryDocument)
    }

    @MainActor
    func testLoadDocumentRequest() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url, request: URLRequest(url: url))

        subject.enqueueDocument(document)

        XCTAssertFalse(subject.shouldDownloadDocument(URLRequest(url: url)))
        XCTAssertNotNil(subject.temporaryDocument)
    }

    @MainActor
    func testReload_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        document.isDownloading = true
        subject.webView = mockTabWebView
        subject.enqueueDocument(document)

        subject.reload()
        subject.webView = nil

        XCTAssertNil(subject.temporaryDocument)
        XCTAssertEqual(mockTabWebView.loadFileURLCalled, 1)
        XCTAssertEqual(mockTabWebView.reloadFromOriginCalled, 1)
    }

    @MainActor
    func testGoBack_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

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

    @MainActor
    func testGoForward_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

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

    @MainActor
    func testLoadRequest_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

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

    @MainActor
    func testStop_whenDocumentIsDownloading_cancelDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument(withFileURL: url)

        subject.webView = mockTabWebView
        document.isDownloading = true

        subject.enqueueDocument(document)
        subject.stop()
        subject.webView = nil

        XCTAssertEqual(mockTabWebView.loadFileURLCalled, 1)
        XCTAssertEqual(mockTabWebView.stopLoadingCalled, 1)
        XCTAssertEqual(mockTabWebView.reloadFromOriginCalled, 1)
    }

    @MainActor
    func testSetURL_showsOnlineURLForLocalDocument() {
        let subject = createSubject()
        let request = URLRequest(url: URL(string: "https://www.example.com")!)
        let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.pdf")
        let document = MockTemporaryDocument(withFileURL: localURL, request: request)

        subject.enqueueDocument(document)

        subject.url = localURL

        XCTAssertEqual(subject.url, request.url)
    }

    @MainActor
    func testPauseDocumentDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument()

        subject.enqueueDocument(document)
        subject.pauseDocumentDownload()

        XCTAssertEqual(document.pauseDownloadCalled, 1)
    }

    @MainActor
    func testResumeDocumentDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument()

        subject.enqueueDocument(document)
        subject.resumeDocumentDownload()

        XCTAssertEqual(document.resumeDownloadCalled, 1)
    }

    @MainActor
    func testCancelDocumentDownload() {
        let subject = createSubject()
        let document = MockTemporaryDocument()

        subject.enqueueDocument(document)
        subject.cancelDocumentDownload()

        XCTAssertEqual(document.cancelDownloadCalled, 1)
    }

    @MainActor
    func testShouldDownloadDocument_whenDocumentInSession_addsTemporaryDocument() {
        let subject = createSubject()

        let localPDFUrl = URL(string: "file://test.pdf")!
        let onlinePDFUrl = URL(string: "https://example.com/test.pdf")!

        mockFileManager.fileExists = false
        subject.restoreTemporaryDocumentSession([localPDFUrl: onlinePDFUrl])

        let result = subject.shouldDownloadDocument(URLRequest(url: localPDFUrl))

        XCTAssertNotNil(subject.temporaryDocument)
        XCTAssertTrue(result, "result should be the opposite fileManager.fileExists")
    }

    @MainActor
    func testShouldDownloadDocument_whenDocumentNotInSession_returnsTrueForNilTemporaryDocument() {
        let subject = createSubject()

        let localPDFUrl = URL(string: "file://test.pdf")!

        let result = subject.shouldDownloadDocument(URLRequest(url: localPDFUrl))

        XCTAssertNil(subject.temporaryDocument)
        XCTAssertTrue(result)
    }

    @MainActor
    func testShouldDownloadDocument_whenDocumentNotInSession_forwardRequestToTemporaryDocument() {
        let subject = createSubject()
        let document = MockTemporaryDocument()
        subject.temporaryDocument = document

        let localPDFUrl = URL(string: "file://test.pdf")!

        _ = subject.shouldDownloadDocument(URLRequest(url: localPDFUrl))

        XCTAssertEqual(document.canDownloadCalled, 1)
    }

    @MainActor
    func testDeinit_removesAllDocumentInSession() {
        var subject: Tab? = createSubject()
        let session = [
            URL(string: "file://local.pdf")!: URL(string: "https://www.example.com")!,
            URL(string: "file://local2.pdf")!: URL(string: "https://www.example2.com")!,
            URL(string: "file://local3.pdf")!: URL(string: "https://www.example3.com")!
        ]

        subject?.restoreTemporaryDocumentSession(session)

        // deallocate object
        subject = nil

        XCTAssertEqual(mockFileManager.removeItemAtURLCalled, session.count)
    }

    // MARK: - Helpers
    @MainActor
    private func createSubject() -> Tab {
        let subject = Tab(
            profile: mockProfile,
            windowUUID: windowUUID,
            fileManager: mockFileManager,
            dispatchQueue: mockDispatchQueue
        )
        trackForMemoryLeaks(subject)
        return subject
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
