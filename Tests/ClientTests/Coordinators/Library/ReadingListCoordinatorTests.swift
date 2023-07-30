// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
@testable import Client

final class ReadingListCoordinatorTests: XCTestCase {
    var router: MockRouter!
    var parentCoordinator: MockLibraryCoordinatorDelegate!

    override func setUp() {
        super.setUp()
        router = MockRouter(navigationController: UINavigationController())
        parentCoordinator = MockLibraryCoordinatorDelegate()
    }

    override func tearDown() {
        super.tearDown()
        router = nil
        parentCoordinator = nil
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

    private func createSubject() -> ReadingListCoordinator {
        let subject = ReadingListCoordinator(
            parentCoordinator: parentCoordinator,
            router: router
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
