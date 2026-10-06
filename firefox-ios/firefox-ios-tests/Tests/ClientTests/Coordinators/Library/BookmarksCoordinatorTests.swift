// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class BookmarksCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var profile: MockProfile!
    private var parentCoordinator: MockLibraryCoordinatorDelegate!
    private var navigationHandler: MockLibraryNavigationHandler!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        router = MockRouter(navigationController: UINavigationController())
        profile = MockProfile()
        parentCoordinator = MockLibraryCoordinatorDelegate()
        navigationHandler = MockLibraryNavigationHandler()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        router = nil
        profile = nil
        parentCoordinator = nil
        navigationHandler = nil
        try await super.tearDown()
    }

    // MARK: Bookmarks

    func testStart() {
        let subject = createSubject()
        let folder = LocalDesktopFolder()

        subject.start(from: folder)

        XCTAssertTrue(router.pushedViewController is BookmarksViewController)
        XCTAssertEqual(router.pushCalled, 1)
    }

    func testBookmarksAppearanceEnablesInteractivePopGestureAndRestoresItsDelegate() throws {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let originalGestureDelegate = MockInteractivePopGestureDelegate()
        navigationController.interactivePopGestureRecognizer?.delegate = originalGestureDelegate
        router = MockRouter(navigationController: navigationController)
        let subject = createSubject()

        subject.start(from: LocalDesktopFolder())
        let controller = try XCTUnwrap(router.pushedViewController as? BookmarksViewController)
        navigationController.interactivePopGestureRecognizer?.isEnabled = false

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        XCTAssertEqual(navigationController.interactivePopGestureRecognizer?.isEnabled, true)
        XCTAssertTrue(navigationController.interactivePopGestureRecognizer?.delegate === controller)

        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()

        XCTAssertTrue(navigationController.interactivePopGestureRecognizer?.delegate === originalGestureDelegate)
    }

    func testBookmarksDeleteSwipeAction_avoidsDestructiveStyleAnimation() throws {
        let subject = createSubject()
        subject.start(from: LocalDesktopFolder())
        let controller = try XCTUnwrap(router.pushedViewController as? BookmarksViewController)

        let configuration = try XCTUnwrap(
            controller.tableView(
                controller.tableView,
                trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0)
            )
        )
        let deleteAction = try XCTUnwrap(configuration.actions.first)

        XCTAssertEqual(deleteAction.style, .normal)
        XCTAssertEqual(deleteAction.backgroundColor, .systemRed)
    }

    func testShowBookmarksDetail_forFolder() {
        let subject = createSubject()
        let folder = LocalDesktopFolder()

        subject.showBookmarkDetail(for: folder, folder: folder)

        XCTAssertTrue(router.pushedViewController is EditFolderViewController)
        XCTAssertEqual(router.pushCalled, 1)
    }

    func testShowBookmarksDetail_forFolder_doesNotLeakController() {
        let subject = createSubject()
        let folder = LocalDesktopFolder()

        subject.showBookmarkDetail(for: folder, folder: folder)

        guard let controller = router.pushedViewController as? EditFolderViewController else {
            return XCTFail("Expected EditFolderViewController to be pushed")
        }
        trackForMemoryLeaks(controller)
        router.pushedViewController = nil
        router.topViewController = nil
        router.navigationController.setViewControllers([], animated: false)
    }

    func testShowBookmarkDetail_forBookmarkCreation() {
        let subject = createSubject()

        subject.showBookmarkDetail(bookmarkType: .bookmark, parentBookmarkFolder: LocalDesktopFolder())

        XCTAssertTrue(router.pushedViewController is EditBookmarkViewController)
        XCTAssertEqual(router.pushCalled, 1)
    }

    func testShowBookmarkDetail_forFolderCreation() {
        let subject = createSubject()

        subject.showBookmarkDetail(bookmarkType: .folder, parentBookmarkFolder: LocalDesktopFolder())

        XCTAssertTrue(router.pushedViewController is EditFolderViewController)
        XCTAssertEqual(router.pushCalled, 1)
    }

    // MARK: Sign in

    func testShowSignInViewController() {
        let subject = createSubject()

        subject.showSignIn()
        let presentedViewController = router.presentedViewController as? UINavigationController
        XCTAssertTrue(presentedViewController?.visibleViewController is FirefoxAccountSignInViewController)
        XCTAssertEqual(router.presentCalled, 1)
    }

    func testShowQRCode_addsQRCodeChildCoordinator() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is QRCodeCoordinator)
    }

    func testShowQRCode_presentsQRCodeNavigationController() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is QRCodeNavigationController)
    }

    // MARK: Did finish

    func testDidFinishCalled() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()
        subject.showQRCode(delegate: delegate)

        guard let qrCodeCoordinator = subject.childCoordinators.first(where: {
            $0 is QRCodeCoordinator
        }) as? QRCodeCoordinator else {
            XCTFail("QRCodeCoordinator expected to be found")
            return
        }

        subject.didFinish(from: qrCodeCoordinator)
        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    // MARK: Share sheet

    func testShowShareSheet_callsNavigationHandlerShareFunction() {
        let subject = createSubject()

        subject.shareLibraryItem(
            url: URL(
                string: "https://www.google.com"
            )!,
            sourceView: UIView()
        )

        XCTAssertEqual(navigationHandler.didShareLibraryItemCalled, 1)
    }

    // MARK: Helper methods

    private func createSubject() -> BookmarksCoordinator {
        let subject = BookmarksCoordinator(
            router: router,
            profile: profile,
            windowUUID: .XCTestDefaultUUID,
            libraryCoordinator: parentCoordinator,
            libraryNavigationHandler: navigationHandler
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

private final class MockInteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate { }
