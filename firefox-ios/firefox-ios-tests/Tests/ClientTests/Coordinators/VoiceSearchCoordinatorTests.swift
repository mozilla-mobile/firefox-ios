// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import QuickAnswersKit
@testable import Client

@MainActor
final class QuickAnswersCoordinatorTests: XCTestCase {
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

    func test_start_presentsViewController() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is QuickAnswersViewController)
    }

    func test_dismissQuickAnswers_dismissesControllerAndNotifiesParent() {
        let subject = createSubject()

        subject.dismissQuickAnswers(with: nil)

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_dismissQuickAnswers_withNilNavigationType_doesntCallCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigate: { _ in
            didCallCallback = true
        })

        subject.dismissQuickAnswers(with: nil)

        XCTAssertFalse(didCallCallback, "The onNavigate closure should not have been called")
    }

    func test_dismissQuickAnswers_withNavigateToURLType_callsCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigate: { type in
            XCTAssertEqual(type, .url(self.testURL))
            didCallCallback = true
        })

        subject.dismissQuickAnswers(with: .url(testURL))

        XCTAssertTrue(didCallCallback, "The onNavigate closure should have been called")
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_dismissQuickAnswers_withNavigateToSearchResultType_callsCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigate: { type in
            XCTAssertEqual(type, .searchResult(self.testQuery))
            didCallCallback = true
        })

        subject.dismissQuickAnswers(with: .searchResult(testQuery))

        XCTAssertTrue(didCallCallback, "The onNavigate closure should have been called")
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    // MARK: - Helper Methods
    private func createSubject(
        onNavigate: @escaping (QuickAnswersNavigationType) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuickAnswersCoordinator {
        let subject = QuickAnswersCoordinator(
            parentCoordinatorDelegate: parentCoordinator,
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            router: router,
            onNavigate: onNavigate
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
