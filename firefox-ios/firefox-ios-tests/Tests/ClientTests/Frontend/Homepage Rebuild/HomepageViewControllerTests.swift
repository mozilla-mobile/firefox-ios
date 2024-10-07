// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class HomepageViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var mockNotificationCenter: MockNotificationCenter?
    var mockThemeManager: MockThemeManager?

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // MARK: - Initial State
    func testInitialCreation_hasCorrectContentType() {
        let sut = createSubject()

        XCTAssertEqual(sut.contentType, .newHomepage)
    }

    func testInitialCreation_hasCorrectWindowUUID() {
        let sut = createSubject()

        XCTAssertEqual(sut.currentWindowUUID, .XCTestDefaultUUID)
    }

    func test_viewDidLoad_setsUpTheming() {
        let sut = createSubject()

        XCTAssertEqual(mockThemeManager?.getCurrentThemeCallCount, 0)
        XCTAssertEqual(mockNotificationCenter?.addObserverCallCount, 0)

        sut.loadViewIfNeeded()

        // Called in listenForThemeChange() and applyTheme(), so counted twice
        XCTAssertEqual(mockThemeManager?.getCurrentThemeCallCount, 1)
        XCTAssertEqual(mockNotificationCenter?.addObserverCallCount, 1)
    }

    // MARK: - Deinit State
    func testDeinit_callsAppropriateNotificationCenterMethods() {
        var sut: NewHomepageViewController? = createSubject()

        XCTAssertNotNil(sut)
        XCTAssertEqual(mockNotificationCenter?.removeObserverCallCount, 0)

        sut = nil

        XCTAssertNil(sut)
        XCTAssertEqual(mockNotificationCenter?.removeObserverCallCount, 1)
    }

    private func createSubject() -> NewHomepageViewController {
        let notificationCenter = MockNotificationCenter()
        let themeManager = MockThemeManager()
        mockNotificationCenter = notificationCenter
        mockThemeManager = themeManager
        let homepageViewController = NewHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            notificationCenter: notificationCenter
        )
        trackForMemoryLeaks(homepageViewController)
        return homepageViewController
    }
}
