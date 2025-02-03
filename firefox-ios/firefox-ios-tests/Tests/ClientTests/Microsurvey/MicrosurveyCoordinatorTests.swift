// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class MicrosurveyCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var mockTabManager: MockTabManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockRouter = MockRouter(navigationController: MockNavigationController())
        mockTabManager = MockTabManager()
    }

    override func tearDown() {
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testInitialState() {
        _ = createSubject()

        XCTAssertFalse(mockRouter.rootViewController is MicrosurveyViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
    }

    func testStart_presentsMicrosurveyController() throws {
        let subject = createSubject()

        subject.start()

        XCTAssertTrue(mockRouter.rootViewController is MicrosurveyViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
    }

    func testMicrosurveyDelegate_dismissFlow_callsRouterDismiss() throws {
        let subject = createSubject()

        subject.start()
        subject.dismissFlow()

        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    func testMicrosurveyDelegate_showPrivacy_callsRouterDismiss_andCreatesNewTab() throws {
        let subject = createSubject()
        let languageIdentifier = Locale.preferredLanguages.first ?? ""

        subject.start()
        subject.showPrivacy(with: nil)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertEqual(mockTabManager.addTabsForURLsCalled, 1)
        XCTAssertEqual(mockTabManager.addTabsURLs, [URL(string: "https://www.mozilla.org/\(languageIdentifier)/privacy/firefox/?utm_medium=firefox-mobile&utm_source=modal&utm_campaign=microsurvey")])
    }

    func testMicrosurveyDelegate_showPrivacyWithContentParams_callsRouterDismiss_andCreatesNewTab() throws {
        let subject = createSubject()
        let languageIdentifier = Locale.preferredLanguages.first ?? ""

        subject.start()
        subject.showPrivacy(with: "homepage")

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertEqual(mockTabManager.addTabsForURLsCalled, 1)
        XCTAssertEqual(mockTabManager.addTabsURLs, [URL(string: "https://www.mozilla.org/\(languageIdentifier)/privacy/firefox/?utm_medium=firefox-mobile&utm_source=modal&utm_campaign=microsurvey&utm_content=homepage")])
    }

    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> MicrosurveyCoordinator {
        let subject = MicrosurveyCoordinator(
            model: MicrosurveyMock.model,
            router: mockRouter,
            tabManager: mockTabManager
        )

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
