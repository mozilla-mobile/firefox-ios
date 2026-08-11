// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

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
        subject.start(payload: WebCompatReportPayload())

        router.savedCompletion?()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func test_technicalDataDidRequestDismiss_dismissesAndNotifiesParent() {
        let subject = createSubject()
        subject.start(payload: WebCompatReportPayload())

        subject.webCompatTechnicalDataDidRequestDismiss()

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // MARK: - Helper Methods
    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> WebCompatReportPreviewCoordinator {
        let subject = WebCompatReportPreviewCoordinator(
            router: router,
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            parentCoordinator: parentCoordinator
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
