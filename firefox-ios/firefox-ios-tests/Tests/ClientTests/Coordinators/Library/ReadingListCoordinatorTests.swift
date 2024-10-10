// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage
import XCTest

@testable import Client

final class ReadingListCoordinatorTests: XCTestCase {
    var router: MockRouter!
    var parentCoordinator: MockLibraryCoordinatorDelegate!
    private var navigationHandler: MockLibraryNavigationHandler!

    override func setUp() {
        super.setUp()
        router = MockRouter(navigationController: UINavigationController())
        parentCoordinator = MockLibraryCoordinatorDelegate()
        navigationHandler = MockLibraryNavigationHandler()
    }

    override func tearDown() {
        router = nil
        parentCoordinator = nil
        navigationHandler = nil
        super.tearDown()
    }

    func testOpenUrl() {
        let subject = createSubject()
        let urlToOpen = URL(string: "https://www.google.com")!

        subject.openUrl(urlToOpen, visitType: .bookmark)

        XCTAssertTrue(parentCoordinator.didSelectURLCalled)
        XCTAssertFalse(parentCoordinator.didRequestToOpenInNewTabCalled)
        XCTAssertEqual(parentCoordinator.didFinishSettingsCalled, 0)
        XCTAssertEqual(parentCoordinator.lastVisitType, VisitType.bookmark)
        XCTAssertEqual(parentCoordinator.lastOpenedURL, urlToOpen)
    }

    func testShowShareExtension_callsNavigationHandlerShareFunction() {
        let subject = createSubject()

        subject.shareLibraryItem(
            url: URL(
                string: "https://www.google.com"
            )!,
            sourceView: UIView()
        )

        XCTAssertEqual(navigationHandler.didShareLibraryItemCalled, 1)
    }

    private func createSubject() -> ReadingListCoordinator {
        let subject = ReadingListCoordinator(
            parentCoordinator: parentCoordinator,
            navigationHandler: navigationHandler,
            router: router
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
