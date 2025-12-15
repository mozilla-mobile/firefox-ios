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
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)

        viewModel = MockLaunchScreenViewModel(windowUUID: windowUUID, profile: MockProfile())
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
        subject.startLoading()

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
        subject.startLoading()

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 0)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
        XCTAssertEqual(viewModel.startLoadingCalled, 1)
    }

    @MainActor
    func testAddLaunchView_whenViewWillAppear() {
        let subject = LaunchScreenViewController(windowUUID: windowUUID,
                                                 coordinator: coordinatorDelegate,
                                                 viewModel: viewModel)
        XCTAssertTrue(subject.view.subviews.isEmpty)
        subject.viewWillAppear(false)
        XCTAssertNotNil(subject.view.subviews[0])
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
