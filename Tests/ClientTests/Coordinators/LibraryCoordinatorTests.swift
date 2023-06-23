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
        super.tearDown()
        self.mockRouter = nil
        self.delegate = nil
        DependencyHelperMock().reset()
    }

    func testEmptyChilds_whenCreated() {
        let subject = createSubject()
        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    func testStart_withBookmarksHomepanelSection_setsUpLibraryViewControllerWithBookmarksPanel() {
        let subject = createSubject()
        subject.start(with: .bookmarks)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertTrue(mockRouter.rootViewController is LibraryViewController)
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

    func testParentCoordinatorDelegate_calledDidFinish() {
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.didFinish()

        XCTAssertEqual(delegate.didFinishSettingsCalled, 1)
    }

    // MARK: - Helper
    func createSubject() -> LibraryCoordinator {
        let subject = LibraryCoordinator(router: mockRouter)
        trackForMemoryLeaks(subject)
        return subject
    }
}

class MockLibraryCoordinatorDelegate: LibraryCoordinatorDelegate, LibraryPanelDelegate {
    var didFinishSettingsCalled = 0

    func didFinishLibrary(from coordinator: LibraryCoordinator) {
        didFinishSettingsCalled += 1
    }

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {}

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {}
}
