// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

final class LaunchScreenViewControllerTests: XCTestCase, LaunchFinishedLoadingDelegate {
    private var viewModel: MockLaunchScreenViewModel!
    private var launchTypeLoadedClosure: ((LaunchType) -> Void)?
    private var launchBrowserClosure: (() -> Void)?

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        viewModel = MockLaunchScreenViewModel(profile: MockProfile())
        viewModel.delegate = self
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        viewModel = nil
        launchTypeLoadedClosure = nil
        launchBrowserClosure = nil
    }

    func testNotLoaded_notCalled() {
        _ = LaunchScreenViewController(coordinator: self,
                                       viewModel: viewModel)
        XCTAssertEqual(viewModel.startLoadingCalled, 0)
    }

    func testViewDidLoad_whenLaunchType_callsCoordinatorLaunch() {
        viewModel.mockLaunchType = .intro(manager: viewModel.introScreenManager)
        let expectation = expectation(description: "LaunchTypeLoaded called")
        launchTypeLoadedClosure = { launchType in
            guard case .intro = launchType else {
                XCTFail("Expected intro, but was \(launchType)")
                return
            }
            expectation.fulfill()
        }
        let subject = LaunchScreenViewController(coordinator: self,
                                                 viewModel: viewModel)
        subject.viewDidLoad()

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(viewModel.startLoadingCalled, 1)
    }

    func testViewDidLoad_whenNilLaunchType_callsCoordinatorBrowser() {
        viewModel.mockLaunchType = nil
        let expectation = expectation(description: "LaunchBrowserClosure called")
        launchBrowserClosure = { expectation.fulfill() }

        let subject = LaunchScreenViewController(coordinator: self,
                                                 viewModel: viewModel)
        subject.viewDidLoad()

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(viewModel.startLoadingCalled, 1)
    }

    func testAddLaunchView_whenViewWillAppear() {
        let subject = LaunchScreenViewController(coordinator: self,
                                                 viewModel: viewModel)
        XCTAssertTrue(subject.view.subviews.isEmpty)
        subject.viewWillAppear(false)
        XCTAssertNotNil(subject.view.subviews[0])
    }

    // MARK: - LaunchFinishedLoadingDelegate

    func launchWith(launchType: LaunchType) {
        launchTypeLoadedClosure?(launchType)
    }

    func launchBrowser() {
        launchBrowserClosure?()
    }
}
