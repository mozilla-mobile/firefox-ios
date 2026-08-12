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
    private var themeManager: MockThemeManager!
    private let reportedURL = URL(string: "https://example.com")!
    private let learnMoreURL = URL(string: "https://example.com/learn-more")!

    override func setUp() async throws {
        try await super.setUp()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
        navigationDelegate = MockWebCompatReportCoordinatorNavigationDelegate()
        themeManager = MockThemeManager()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        router = nil
        parentCoordinator = nil
        navigationDelegate = nil
        themeManager = nil
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

    func test_viewControllerDidTapLearnMore_keepsTheSheetUp() {
        let subject = createSubject()
        subject.start(reportedURL: reportedURL)

        subject.webCompatReportViewControllerDidTapLearnMore(url: learnMoreURL)

        // Dismissing would tear the sheet's Redux state down and lose the in-progress report.
        XCTAssertEqual(router.dismissCalled, 0)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 0)
    }

    func test_didTapPreview_addsThePreviewAsAChild() {
        let subject = createSubject()
        subject.start(reportedURL: reportedURL)

        subject.webCompatReportViewControllerDidTapPreview(payload: WebCompatReportPayload())

        XCTAssertTrue(subject.childCoordinators.first is WebCompatReportPreviewCoordinator)
        XCTAssertEqual(subject.childCoordinators.count, 1)
    }

    func test_didTapPreview_whileOneIsOpen_doesNotStartASecond() {
        let subject = createSubject()
        subject.start(reportedURL: reportedURL)

        subject.webCompatReportViewControllerDidTapPreview(payload: WebCompatReportPayload())
        subject.webCompatReportViewControllerDidTapPreview(payload: WebCompatReportPayload())

        XCTAssertEqual(subject.childCoordinators.count, 1)
    }

    // A child left behind blocks the guard above, which kept Preview dead for the rest of the form.
    func test_previewDidFinish_removesItSoPreviewOpensAgain() throws {
        let subject = createSubject()
        subject.start(reportedURL: reportedURL)
        subject.webCompatReportViewControllerDidTapPreview(payload: WebCompatReportPayload())
        let previewCoordinator = try XCTUnwrap(subject.childCoordinators.first)

        subject.didFinish(from: previewCoordinator)
        XCTAssertTrue(subject.childCoordinators.isEmpty)

        subject.webCompatReportViewControllerDidTapPreview(payload: WebCompatReportPayload())
        XCTAssertEqual(subject.childCoordinators.count, 1)
    }

    // MARK: - Helper Methods
    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> WebCompatReportCoordinator {
        let subject = WebCompatReportCoordinator(
            router: router,
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            parentCoordinatorDelegate: parentCoordinator,
            navigationDelegate: navigationDelegate
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

private final class MockWebCompatReportCoordinatorNavigationDelegate: WebCompatReportCoordinatorNavigationDelegate {
    var didSubmitCalled = 0

    func webCompatReportDidSubmit() {
        didSubmitCalled += 1
    }
}
