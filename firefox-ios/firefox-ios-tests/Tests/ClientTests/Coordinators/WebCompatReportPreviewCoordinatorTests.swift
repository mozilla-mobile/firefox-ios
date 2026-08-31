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
    private var previewRouter: MockRouter!
    private var previewRouterNavigationController: UINavigationController?
    private var parentCoordinator: MockParentCoordinator!
    private var themeManager: MockThemeManager!

    override func setUp() async throws {
        try await super.setUp()
        router = MockRouter(navigationController: MockNavigationController())
        previewRouter = MockRouter(navigationController: MockNavigationController())
        previewRouterNavigationController = nil
        parentCoordinator = MockParentCoordinator()
        themeManager = MockThemeManager()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        router = nil
        previewRouter = nil
        previewRouterNavigationController = nil
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

        let sheetNavigationController = try XCTUnwrap(router.presentedViewController as? UINavigationController)
        XCTAssertIdentical(previewRouterNavigationController, sheetNavigationController)
        XCTAssertEqual(router.pushCalled, 0)
        XCTAssertEqual(previewRouter.pushCalled, 1)
        let pushed = try XCTUnwrap(previewRouter.pushedViewController as? WebCompatTechnicalDataViewController)
        XCTAssertIdentical(pushed.delegate, subject)
        let root = try XCTUnwrap(
            sheetNavigationController.viewControllers.first as? WebCompatReportPreviewViewController
        )
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
            parentCoordinator: parentCoordinator,
            previewRouterFactory: { [unowned self] navigationController in
                previewRouterNavigationController = navigationController
                return previewRouter
            }
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
