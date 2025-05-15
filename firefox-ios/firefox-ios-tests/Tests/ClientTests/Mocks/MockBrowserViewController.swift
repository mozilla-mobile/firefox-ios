// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@testable import Client

import enum MozillaAppServices.VisitType

class MockBrowserViewController: BrowserViewController {
    var switchToTabForURLOrOpenCalled = false
    var switchToTabForURLOrOpenURL: URL?
    var switchToTabForURLOrOpenUUID: String?
    var switchToTabForURLOrOpenIsPrivate = false

    var openBlankNewTabCalled = false
    var openBlankNewTabFocusLocationField = false
    var openBlankNewTabIsPrivate = false
    var openBlankNewTabSearchText: String?

    var handleQueryCalled = false
    var handleQuery: String?
    var showLibraryCalled = false
    var showLibraryPanel: LibraryPanelType?

    var openURLInNewTabCalled = false
    var openURLInNewTabURL: URL?
    var openURLInNewTabIsPrivate = false

    var switchToTabForURLOrOpenCount = 0
    var openBlankNewTabCount = 0
    var handleQueryCount = 0
    var showLibraryCount = 0
    var openURLInNewTabCount = 0
    var presentSignInFxaOptions: FxALaunchParams?
    var presentSignInFlowType: FxAPageType?
    var presentSignInReferringPage: ReferringPage?
    var presentSignInCount = 0

    var qrCodeCount = 0
    var closePrivateTabsWidgetAction = 0

    var embedContentCalled = 0
    var frontEmbeddedContentCalled = 0
    var saveEmbeddedContent: ContentContainable?

    var didRequestToOpenInNewTabCalled = false
    var didSelectURLCalled = false
    var lastOpenedURL: URL?
    var lastVisitType: VisitType?
    var isPrivate = false

    var showDocumentLoadingViewCalled = 0
    var removeDocumentLoadingViewCalled = 0

    var mockContentContainer = MockContentContainer()

    var viewControllerToPresent: UIViewController?

    override var presentedViewController: UIViewController? {
        return viewControllerToPresent
    }

    override var contentContainer: ContentContainer {
        return mockContentContainer
    }

    override func switchToTabForURLOrOpen(
        _ url: URL,
        uuid: String?,
        isPrivate: Bool,
        completionHandler: (() -> Void)? = nil
    ) {
        switchToTabForURLOrOpenCalled = true
        switchToTabForURLOrOpenURL = url
        switchToTabForURLOrOpenUUID = uuid
        switchToTabForURLOrOpenIsPrivate = isPrivate
        switchToTabForURLOrOpenCount += 1
        completionHandler?()
    }

    override func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool, searchFor searchText: String?) {
        openBlankNewTabCalled = true
        openBlankNewTabFocusLocationField = focusLocationField
        openBlankNewTabIsPrivate = isPrivate
        openBlankNewTabSearchText = searchText
        openBlankNewTabCount += 1
    }

    override func handle(query: String, isPrivate: Bool) {
        handleQueryCalled = true
        handleQuery = query
        handleQueryCount += 1
    }

    override func showLibrary(panel: LibraryPanelType?) {
        showLibraryCalled = true
        showLibraryPanel = panel
        showLibraryCount += 1
    }

    override func openURLInNewTab(_ url: URL?, isPrivate: Bool) -> Tab {
        openURLInNewTabCalled = true
        openURLInNewTabURL = url
        openURLInNewTabIsPrivate = isPrivate
        openURLInNewTabCount += 1
        return Tab(profile: MockProfile(), windowUUID: windowUUID)
    }

    override func handleQRCode() {
        qrCodeCount += 1
    }

    override func closeAllPrivateTabs() {
        closePrivateTabsWidgetAction += 1
    }

    override func presentSignInViewController(
        _ fxaOptions: FxALaunchParams,
        flowType: FxAPageType = .emailLoginFlow,
        referringPage: ReferringPage = .none
    ) {
        presentSignInFxaOptions = fxaOptions
        presentSignInFlowType = flowType
        presentSignInReferringPage = referringPage
        presentSignInCount += 1
    }

    override func embedContent(_ viewController: ContentContainable) -> Bool {
        embedContentCalled += 1
        saveEmbeddedContent = viewController
        return true
    }

    override func frontEmbeddedContent(_ viewController: ContentContainable) {
        frontEmbeddedContentCalled += 1
        saveEmbeddedContent = viewController
    }

    override func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        didRequestToOpenInNewTabCalled = true
        lastOpenedURL = url
        self.isPrivate = isPrivate
    }

    override func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        didSelectURLCalled = true
        lastOpenedURL = url
        lastVisitType = visitType
    }

    override func showDocumentLoadingView() {
        showDocumentLoadingViewCalled += 1
    }

    override func removeDocumentLoadingView() {
        removeDocumentLoadingViewCalled += 1
    }
}

class MockContentContainer: ContentContainer {
    var shouldHaveNativeErrorPage = false

    override var contentView: Screenshotable? {
        return MockScreenshotView()
    }

    override var hasNativeErrorPage: Bool {
        return shouldHaveNativeErrorPage
    }
}

class MockScreenshotView: Screenshotable {
    func screenshot(quality: CGFloat) -> UIImage? {
        return UIImage.checkmark
    }
}
