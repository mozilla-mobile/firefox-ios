// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

@MainActor
final class LaunchScreenViewControllerTests: XCTestCase {
    private var viewModel: MockLaunchScreenViewModel!
    private var profile: MockProfile!
    private var coordinatorDelegate: MockLaunchFinishedLoadingDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()

        viewModel = MockLaunchScreenViewModel(windowUUID: windowUUID, profile: profile)
        coordinatorDelegate = MockLaunchFinishedLoadingDelegate()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        viewModel = nil
        profile = nil
        coordinatorDelegate = nil

        try await super.tearDown()
    }

    @MainActor
    func testNotLoaded_notCalled() {
        _ = createSubject()
        XCTAssertEqual(viewModel.startLoadingCalled, 0)
    }

    @MainActor
    func testViewDidLoad_whenLaunchType_callsCoordinatorLaunch() {
        viewModel.mockLaunchType = .intro(manager: viewModel.introScreenManager)
        let subject = createSubject()
        subject.loadViewIfNeeded()

        guard case .intro = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected intro, but was \(String(describing: coordinatorDelegate.savedLaunchType))")
            return
        }
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 0)
        XCTAssertEqual(viewModel.startLoadingCalled, 1)
    }

    @MainActor
    func testViewDidLoad_whenNilLaunchType_callsCoordinatorBrowser() {
        viewModel.mockLaunchType = nil
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 0)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
        XCTAssertEqual(viewModel.startLoadingCalled, 1)
    }

    @MainActor
    func testViewDidLoad_addsLaunchScreenSubview() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertFalse(subject.view.subviews.isEmpty)
    }

    @MainActor
    func testViewWillAppear_callsLoadNextLaunchType() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        XCTAssertEqual(viewModel.loadNextLaunchTypeCalled, 0)

        subject.viewWillAppear(false)

        XCTAssertEqual(viewModel.loadNextLaunchTypeCalled, 1)
    }

    @MainActor
    func testLaunchWith_forwardsToCoordinator() {
        let subject = createSubject()
        let launchType: LaunchType = .intro(manager: viewModel.introScreenManager)

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .intro = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected intro launch type")
            return
        }
    }

    @MainActor
    func testLaunchBrowser_forwardsToCoordinator() {
        let subject = createSubject()

        subject.launchBrowser()

        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 0)
    }

    @MainActor
    func testFinishedLoadingLaunchOrder_callsLoadNextLaunchType() {
        let subject = createSubject()

        subject.finishedLoadingLaunchOrder()

        XCTAssertEqual(viewModel.loadNextLaunchTypeCalled, 1)
    }

    // MARK: - Helpers
    @MainActor
    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> LaunchScreenViewController {
        let subject = LaunchScreenViewController(windowUUID: windowUUID,
                                                 coordinator: coordinatorDelegate,
                                                 viewModel: viewModel)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
