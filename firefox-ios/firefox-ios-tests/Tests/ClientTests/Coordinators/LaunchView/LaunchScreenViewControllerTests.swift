// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

final class LaunchScreenViewControllerTests: XCTestCase {
    private var viewModel: MockLaunchScreenViewModel!
    private var profile: MockProfile!
    private var coordinatorDelegate: MockLaunchFinishedLoadingDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)

        viewModel = MockLaunchScreenViewModel(windowUUID: windowUUID, profile: MockProfile())
        coordinatorDelegate = MockLaunchFinishedLoadingDelegate()
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        viewModel = nil
        profile = nil
        coordinatorDelegate = nil
    }

    func testNotLoaded_notCalled() {
        _ = createSubject()
        XCTAssertEqual(viewModel.startLoadingCalled, 0)
    }

    @MainActor
    func testViewDidLoad_whenLaunchType_callsCoordinatorLaunch() async {
        viewModel.mockLaunchType = .intro(manager: viewModel.introScreenManager)
        let subject = createSubject()
        await subject.startLoading()

        guard case .intro = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected intro, but was \(String(describing: coordinatorDelegate.savedLaunchType))")
            return
        }
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 0)
        XCTAssertEqual(viewModel.startLoadingCalled, 1)
    }

    @MainActor
    func testViewDidLoad_whenNilLaunchType_callsCoordinatorBrowser() async {
        viewModel.mockLaunchType = nil
        let subject = createSubject()
        await subject.startLoading()

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 0)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
        XCTAssertEqual(viewModel.startLoadingCalled, 1)
    }

    func testAddLaunchView_whenViewWillAppear() {
        let subject = LaunchScreenViewController(windowUUID: windowUUID,
                                                 coordinator: coordinatorDelegate,
                                                 viewModel: viewModel)
        XCTAssertTrue(subject.view.subviews.isEmpty)
        subject.viewWillAppear(false)
        XCTAssertNotNil(subject.view.subviews[0])
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> LaunchScreenViewController {
        let subject = LaunchScreenViewController(windowUUID: windowUUID,
                                                 coordinator: coordinatorDelegate,
                                                 viewModel: viewModel)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
