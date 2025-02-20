// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import XCTest

@testable import Client

final class ContextMenuCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() {
        mockRouter = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func test_initialState() {
        _ = createSubject()

        XCTAssertFalse(mockRouter.presentedViewController is PhotonActionSheet)
        XCTAssertEqual(mockRouter.presentCalled, 0)
    }

    func test_start_presentsContextMenuController() throws {
        let subject = createSubject()

        subject.start()

        XCTAssertTrue(mockRouter.presentedViewController is PhotonActionSheet)
        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    func test_dismissFlow_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.start()
        subject.dismissFlow()

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> ContextMenuCoordinator {
        let configuration = ContextMenuConfiguration(homepageSection: .header, toastContainer: UIView())
        let subject = ContextMenuCoordinator(
            configuration: configuration,
            router: mockRouter,
            windowUUID: .XCTestDefaultUUID,
            bookmarksHandlerDelegate: MockBookmarksHandlerDelegate()
        )

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

class MockBookmarksHandlerDelegate: BookmarksHandlerDelegate {
    func addBookmark(urlString: String, title: String?, site: Site?) { }
    func removeBookmark(urlString: String, title: String?, site: Site?) { }
}
