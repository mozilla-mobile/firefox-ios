// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class NewHomepageViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override class func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testNewHomepageViewController_hasCorrectContentType() {
        let sut = createSubject()
        XCTAssertEqual(sut.contentType, .newHomepage)
    }

//    func testNewHomepageViewController_notificationCalled() {
//        let sut = createSubject()
//        XCTAssertEqual(sut.contentType, .newHomepage)
//        sut = nil
//        XCTAssertEqual(sut.contentType, .newHomepage)
//    }

    private func createSubject() -> NewHomepageViewController {
        let mockNotificationCenter = MockNotificationCenter()
        let homepageViewController = NewHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            notificationCenter: mockNotificationCenter
        )
        trackForMemoryLeaks(homepageViewController)
        return homepageViewController
    }
}
