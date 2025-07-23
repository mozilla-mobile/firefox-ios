// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import SummarizeKit
@testable import Client

@MainActor
final class SummarizeCoordinatorTests: XCTestCase {
    private var browserViewController: MockBrowserViewController!
    private var router: MockRouter!
    private var parentCoordinator: MockParentCoordinator!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        browserViewController = MockBrowserViewController(profile: MockProfile(), tabManager: MockTabManager())
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        browserViewController = nil
        router = nil
        parentCoordinator = nil
        super.tearDown()
    }

    func testStart() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is SummarizeController)
    }

    func testDeinit_callsParentCoordinatorDelegate() {
        let subject = createSubject()

        subject.start()
        router.presentedViewController?.dismiss(animated: false)

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    private func createSubject() -> SummarizeCoordinator {
        let subject = SummarizeCoordinator(browserSnapshot: UIImage(),
                                           browserSnapshotTopOffset: 0.0,
                                           browserContentHiding: browserViewController,
                                           parentCoordinatorDelegate: parentCoordinator,
                                           windowUUID: .XCTestDefaultUUID,
                                           router: router)
        trackForMemoryLeaks(subject)
        return subject
    }
}
