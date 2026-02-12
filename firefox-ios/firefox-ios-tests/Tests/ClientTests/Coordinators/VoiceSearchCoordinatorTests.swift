// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import VoiceSearchKit
@testable import Client

@MainActor
final class VoiceSearchCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var parentCoordinator: MockParentCoordinator!
    private var themeManager: MockThemeManager!
    private let testURL = URL(string: "https://example.com")!
    private let testQuery = "test search query"

    override func setUp() async throws {
        try await super.setUp()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
        themeManager = MockThemeManager()
    }

    override func tearDown() async throws {
        router = nil
        parentCoordinator = nil
        themeManager = nil
        try await super.tearDown()
    }

    func test_start_presentsVoiceSearchViewController() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is VoiceSearchViewController)
    }

    func test_dismissVoiceSearch_dismissesControllerAndNotifiesParent() {
        let subject = createSubject()

        subject.dismissVoiceSearch(with: nil)

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_dismissVoiceSearch_withNilNavigationType_doesntCallCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigateTo: { _ in
            didCallCallback = true
        })

        subject.dismissVoiceSearch(with: nil)

        XCTAssertFalse(didCallCallback, "The onNavigateTo closure should not have been called")
    }

    func test_dismissVoiceSearch_withNavigateToURLType_callsCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigateTo: { type in
            XCTAssertEqual(type, .navigateToURL(self.testURL))
            didCallCallback = true
        })

        subject.dismissVoiceSearch(with: .navigateToURL(testURL))

        XCTAssertTrue(didCallCallback, "The onNavigateTo closure should have been called")
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_dismissVoiceSearch_withNavigateToSearchResultType_callsCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigateTo: { type in
            XCTAssertEqual(type, .navigateToSearchResult(self.testQuery))
            didCallCallback = true
        })

        subject.dismissVoiceSearch(with: .navigateToSearchResult(testQuery))

        XCTAssertTrue(didCallCallback, "The onNavigateTo closure should have been called")
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    // MARK: - Helper Methods
    private func createSubject(
        onNavigateTo: @escaping (VoiceSearchNavigationType) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VoiceSearchCoordinator {
        let subject = VoiceSearchCoordinator(
            parentCoordinatorDelegate: parentCoordinator,
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            router: router,
            onNavigateTo: onNavigateTo
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
