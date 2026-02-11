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
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
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

    func test_start_presentsVoiceSearchViewController() throws {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is VoiceSearchViewController)
    }

    func test_dismissVoiceSearch_dismissesControllerAndNotifiesParent() {
        let subject = createSubject()

        subject.dismissVoiceSearch()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func test_navigateToURL_callsCallbackAndDismisses() {
        let expectation = expectation(description: "onNavigatetToURL should be called")
        let subject = createSubject(onNavigateToURL: { url in
            XCTAssertEqual(url, self.testURL)
            expectation.fulfill()
        })

        subject.navigateToURL(testURL)

        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_navigateToSearchResult_callsCallbackAndDismisses() {
        let expectation = expectation(description: "onNavigationToSearchURL should be called")
        let subject = createSubject(onNavigateToSearch: { query in
            XCTAssertEqual(query, self.testQuery)
            expectation.fulfill()
        })

        subject.navigateToSearchResult(testQuery)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    // MARK: - Helper Methods

    private func createSubject(
        onNavigateToURL: @escaping (URL) -> Void = { _ in },
        onNavigateToSearch: @escaping (String) -> Void = { _ in }
    ) -> VoiceSearchCoordinator {
        let subject = VoiceSearchCoordinator(
            parentCoordinatorDelegate: parentCoordinator,
            windowUUID: windowUUID,
            themeManager: themeManager,
            router: router,
            onNavigateToURL: onNavigateToURL,
            onNavigateToSearch: onNavigateToSearch
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
