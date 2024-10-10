// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage

@testable import Client

final class LibraryCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var delegate: MockLibraryCoordinatorDelegate!

    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.delegate = MockLibraryCoordinatorDelegate()
    }

    override func tearDown() {
        self.mockRouter = nil
        self.delegate = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testEmptyChildren_whenCreated() {
        let subject = createSubject()
        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    func testStart_withBookmarksHomepanelSection_setsUpLibraryViewControllerWithBookmarksPanel() {
        let subject = createSubject()
        subject.start(with: .bookmarks)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertTrue(mockRouter.rootViewController is LibraryViewController)
        XCTAssertEqual((mockRouter.rootViewController as? LibraryViewController)?.childPanelControllers.count, 4)
    }

    func testStart_withHistoryHomepanelSection_setsUpLibraryViewControllerWithHistoryPanel() {
        let subject = createSubject()
        subject.start(with: .history)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertTrue(mockRouter.rootViewController is LibraryViewController)
    }

    func testStart_withDownloadsHomepanelSection_setsUpLibraryViewControllerWithDownloadsPanel() {
        let subject = createSubject()
        subject.start(with: .downloads)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertTrue(mockRouter.rootViewController is LibraryViewController)
    }

    func testStart_withReadingListHomepanelSection_setsUpLibraryViewControllerWithReadingListPanel() {
        let subject = createSubject()
        subject.start(with: .readingList)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertTrue(mockRouter.rootViewController is LibraryViewController)
    }

    func testStart_withLibraryPanelTypeBookmarks_addsChildBookmarksCoordinator() {
        let subject = createSubject()
        subject.start(panelType: .bookmarks, navigationController: UINavigationController())
        XCTAssertTrue(subject.childCoordinators.first is BookmarksCoordinator)
        XCTAssertEqual(subject.childCoordinators.count, 1)
    }

    func testStart_withLibraryPanelTypeHistory_addsChildHistoryCoordinator() {
        let subject = createSubject()
        subject.start(panelType: .history, navigationController: UINavigationController())
        XCTAssertTrue(subject.childCoordinators.first is HistoryCoordinator)
        XCTAssertEqual(subject.childCoordinators.count, 1)
    }

    func testStart_withLibraryPanelTypeDownloads_addsChildDownloadsCoordinator() {
        let subject = createSubject()
        subject.start(panelType: .downloads, navigationController: UINavigationController())
        XCTAssertTrue(subject.childCoordinators.first is DownloadsCoordinator)
    }

    func testStart_withLibraryPanelTypeReadingList_addsChildReadingListCoordinator() {
        let subject = createSubject()
        subject.start(panelType: .readingList, navigationController: UINavigationController())
        XCTAssertTrue(subject.childCoordinators.first is ReadingListCoordinator)
        XCTAssertEqual(subject.childCoordinators.count, 1)
    }

    func testParentCoordinatorDelegate_calledDidFinish() {
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.didFinish()

        XCTAssertEqual(delegate.didFinishSettingsCalled, 1)
    }

    func testShowShareExtension_addsShareExtensionCoordinator() {
        let subject = createSubject()

        subject.shareLibraryItem(
            url: URL(
                string: "https://www.google.com"
            )!,
            sourceView: UIView()
        )

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is ShareExtensionCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is UIActivityViewController)
    }

    // MARK: - Helper
    func createSubject() -> LibraryCoordinator {
        let subject = LibraryCoordinator(router: mockRouter, tabManager: MockTabManager())
        trackForMemoryLeaks(subject)
        return subject
    }

    func testTappingOpenUrl_CallsTheDidSelectUrl() throws {
        let subject = createSubject()
        subject.parentCoordinator = delegate
        subject.start(with: .bookmarks)

        let presentedVC = try XCTUnwrap(mockRouter.rootViewController as? LibraryViewController)
        let url = URL(string: "http://google.com")!
        presentedVC.libraryPanel(didSelectURL: url, visitType: .bookmark)

        XCTAssertTrue(delegate.didSelectURLCalled)
        XCTAssertEqual(delegate.lastOpenedURL, url)
        XCTAssertEqual(delegate.lastVisitType, .bookmark)
    }

    func testTappingOpenUrlInNewTab_CallsTheDidSelectUrlInNewTap() throws {
        let subject = createSubject()
        subject.parentCoordinator = delegate
        subject.start(with: .bookmarks)

        let presentedVC = try XCTUnwrap(mockRouter.rootViewController as? LibraryViewController)
        let url = URL(string: "http://google.com")!
        presentedVC.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: true)

        XCTAssertTrue(delegate.didRequestToOpenInNewTabCalled)
        XCTAssertEqual(delegate.lastOpenedURL, url)
        XCTAssertTrue(delegate.isPrivate)
    }
}
