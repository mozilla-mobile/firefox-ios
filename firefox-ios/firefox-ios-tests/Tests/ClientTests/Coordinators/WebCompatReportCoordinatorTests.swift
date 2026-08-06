// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

@MainActor
final class WebCompatReportCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var parentCoordinator: MockParentCoordinator!
    private var navigationDelegate: MockWebCompatReportCoordinatorNavigationDelegate!
    private let reportedURL = URL(string: "https://example.com")!
    private let learnMoreURL = URL(string: "https://example.com/learn-more")!

    override func setUp() async throws {
        try await super.setUp()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
        navigationDelegate = MockWebCompatReportCoordinatorNavigationDelegate()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        router = nil
        parentCoordinator = nil
        navigationDelegate = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_start_presentsViewController() throws {
        let subject = createSubject()

        subject.start(reportedURL: reportedURL)

        let presentedViewController = try XCTUnwrap(router.presentedViewController as? WebCompatReportViewController)

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(presentedViewController.reportCoordinator === subject)
    }

    func test_viewControllerDidFinish_dismissesAndNotifiesParent() {
        let subject = createSubject()

        subject.webCompatReportViewControllerDidFinish()
        router.savedCompletion?()

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // The toast would be covered by the sheet if it went up first.
    func test_viewControllerDidSubmit_confirmsAfterDismissCompletes() {
        let subject = createSubject()

        subject.webCompatReportViewControllerDidSubmit()

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(navigationDelegate.didSubmitCalled, 0)

        router.savedCompletion?()

        XCTAssertEqual(navigationDelegate.didSubmitCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // The explainer would load in a tab hidden behind the sheet if it opened first.
    func test_viewControllerDidTapLearnMore_opensURLAfterDismissCompletes() {
        let subject = createSubject()

        subject.webCompatReportViewControllerDidTapLearnMore(url: learnMoreURL)

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertTrue(navigationDelegate.openedURLs.isEmpty)

        router.savedCompletion?()

        XCTAssertEqual(navigationDelegate.openedURLs, [learnMoreURL])
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // MARK: - Helper Methods
    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> WebCompatReportCoordinator {
        let subject = WebCompatReportCoordinator(
            router: router,
            windowUUID: .XCTestDefaultUUID,
            parentCoordinatorDelegate: parentCoordinator,
            navigationDelegate: navigationDelegate
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

private final class MockWebCompatReportCoordinatorNavigationDelegate: WebCompatReportCoordinatorNavigationDelegate {
    var openedURLs = [URL]()
    var didSubmitCalled = 0

    func webCompatReportOpenURLInNewTab(_ url: URL) {
        openedURLs.append(url)
    }

    func webCompatReportDidSubmit() {
        didSubmitCalled += 1
    }
}
