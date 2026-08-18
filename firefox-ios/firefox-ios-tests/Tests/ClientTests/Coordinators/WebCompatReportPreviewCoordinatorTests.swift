// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import WebCompatReporterKit

@testable import Client

@MainActor
final class WebCompatReportPreviewCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var parentCoordinator: MockParentCoordinator!
    private var themeManager: MockThemeManager!

    override func setUp() async throws {
        try await super.setUp()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
        themeManager = MockThemeManager()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        router = nil
        parentCoordinator = nil
        themeManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // Swiping the sheet down never goes through the coordinator, so the present completion is the
    // only place the parent hears about it.
    func test_swipeDismiss_finishesTheCoordinator() {
        let subject = createSubject()
        subject.start()

        router.savedCompletion?()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func test_technicalDataDidRequestDismiss_dismissesAndNotifiesParent() {
        let subject = createSubject()
        subject.start()

        subject.webCompatTechnicalDataDidRequestDismiss()

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // The injected router is rooted at the report form, so pushing through it would leave Technical
    // Data behind the sheet instead of on top of the preview.
    func test_previewDidTapTechnicalData_pushesOntoTheSheetsOwnStack() throws {
        let subject = createSubject()
        subject.start()

        subject.webCompatReportPreviewDidTapTechnicalData()

        let navigationController = try XCTUnwrap(router.presentedViewController as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertEqual(router.pushCalled, 0)
        let pushed = try XCTUnwrap(navigationController.topViewController as? WebCompatTechnicalDataViewController)
        XCTAssertIdentical(pushed.delegate, subject)
        let root = try XCTUnwrap(navigationController.viewControllers.first as? WebCompatReportPreviewViewController)
        XCTAssertIdentical(root.delegate, subject)
    }

    // MARK: - Helper Methods
    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> WebCompatReportPreviewCoordinator {
        let subject = WebCompatReportPreviewCoordinator(
            payload: WebCompatReportPayload(),
            router: router,
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            parentCoordinator: parentCoordinator
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
