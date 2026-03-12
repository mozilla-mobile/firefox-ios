// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class MainMenuCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testInitialState() {
        _ = createSubject()

        XCTAssertFalse(mockRouter.rootViewController is MicrosurveyViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        XCTAssertEqual(mockRouter.pushCalled, 0)
        XCTAssertEqual(mockRouter.popViewControllerCalled, 0)
    }

    func testStart_presentsMainMenuController() throws {
        let subject = createSubject()

        subject.start()

        XCTAssertTrue(mockRouter.rootViewController is MainMenuViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testMainMenu_dismissFlow_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.start()
        subject.dismissMenuModal(animated: false)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    func testHandleNavigation_readerView_callsShowReaderModeOnDelegate() {
        let subject = createSubject()
        let mockDelegate = MockMainMenuCoordinatorDelegate()
        subject.navigationHandler = mockDelegate

        subject.navigateTo(MenuNavigationDestination(.readerView), animated: false)
        mockRouter.savedCompletion?()

        XCTAssertEqual(mockDelegate.showReaderModeCalled, 1)
    }

    func testHandleNavigation_readerView_dismissesMenuModal() {
        let subject = createSubject()
        subject.navigationHandler = MockMainMenuCoordinatorDelegate()

        subject.navigateTo(MenuNavigationDestination(.readerView), animated: false)
        // First dismiss from navigateTo
        XCTAssertEqual(mockRouter.dismissCalled, 1)

        mockRouter.savedCompletion?()
        // Second dismiss from dismissMenuModal inside handleDestination
        XCTAssertEqual(mockRouter.dismissCalled, 2)
    }

    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MainMenuCoordinator {
        let subject = MainMenuCoordinator(router: mockRouter, windowUUID: .XCTestDefaultUUID, profile: MockProfile())

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

// MARK: - MockMainMenuCoordinatorDelegate

private class MockMainMenuCoordinatorDelegate: MainMenuCoordinatorDelegate {
    var showReaderModeCalled = 0

    func editBookmarkForCurrentTab() {}
    func showLibraryPanel(_ panel: Route.HomepanelSection) {}
    func showSettings(at destination: Route.SettingsSection) {}
    func showFindInPage() {}
    func showSignInView(fxaParameters: FxASignInViewParameters?) {}
    func updateZoomPageBarVisibility() {}
    func presentSavePDFController() {}
    func presentSiteProtections() {}
    func showPrintSheet() {}
    func showReaderMode() { showReaderModeCalled += 1 }
    func showShareSheetForCurrentlySelectedTab() {}
    func showSummarizePanel(_ trigger: SummarizerTrigger, config: SummarizerConfig?) {}
}
