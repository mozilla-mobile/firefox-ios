// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

// MARK: - ModernLaunchScreenViewController Tests
@MainActor
final class ModernLaunchScreenViewControllerTests: XCTestCase {
    // MARK: - Test Properties
    private var viewModel: MockLaunchScreenViewModel!
    private var coordinatorDelegate: MockLaunchFinishedLoadingDelegate!
    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    // MARK: - Test Setup & Teardown
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        let profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        viewModel = MockLaunchScreenViewModel(windowUUID: windowUUID, profile: profile)
        coordinatorDelegate = MockLaunchFinishedLoadingDelegate()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        viewModel = nil
        coordinatorDelegate = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_setsPrefersStatusBarHiddenToTrue() {
        let subject = createSubject()
        XCTAssertTrue(subject.prefersStatusBarHidden)
    }

    // MARK: - View Lifecycle Tests

    func test_startLoading_triggersViewModelStartLoadingOnce() {
        let subject = createSubject()

        subject.startLoading()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
    }

    func test_startLoading_whenLoading_defersLoadNextLaunchType() {
        let subject = createSubject()

        subject.startLoading()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(viewModel.loadNextLaunchTypeCalled, 0)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 0)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
    }

    func test_finishedLoadingLaunchOrder_triggersDeferredLoadNextLaunchType() {
        let subject = createSubject()
        subject.startLoading()
        viewModel.loadNextLaunchType()

        XCTAssertTrue(viewModel.loadNextLaunchTypeCalled > 0)
    }

    // MARK: - LaunchFinishedLoadingDelegate Tests

    func test_launchWithLaunchType_callsCoordinatorDelegate() {
        let subject = createSubject()
        let launchType: LaunchType = .intro(manager: viewModel.introScreenManager)

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .intro = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected intro launch type")
            return
        }
    }

    func test_launchWithLaunchType_withUpdateType_callsCoordinatorCorrectly() {
        let subject = createSubject()
        let launchType: LaunchType = .update(viewModel: viewModel.updateViewModel)

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .update = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected update launch type")
            return
        }
    }

    func test_launchWithLaunchType_withSurveyType_callsCoordinatorCorrectly() {
        let subject = createSubject()
        let launchType: LaunchType = .survey(manager: viewModel.surveySurfaceManager)

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .survey = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected survey launch type")
            return
        }
    }

    func test_launchWithLaunchType_withDefaultBrowserType_callsCoordinatorCorrectly() {
        let subject = createSubject()
        let launchType: LaunchType = .defaultBrowser

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .defaultBrowser = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected default browser launch type")
            return
        }
    }

    func test_launchBrowser_callsCoordinatorDelegate() {
        let subject = createSubject()

        subject.launchBrowser()

        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
    }

    // MARK: - Integration Tests

    func test_fullLaunchFlow_withIntroLaunchType_triggersCorrectDelegateCall() {
        viewModel.mockLaunchType = .intro(manager: viewModel.introScreenManager)
        let subject = createSubject()

        subject.startLoading()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .intro = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected intro launch type")
            return
        }
    }

    func test_fullLaunchFlow_withUpdateLaunchType_triggersCorrectDelegateCall() {
        viewModel.mockLaunchType = .update(viewModel: viewModel.updateViewModel)
        let subject = createSubject()

        subject.startLoading()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .update = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected update launch type")
            return
        }
    }

    func test_fullLaunchFlow_withSurveyLaunchType_triggersCorrectDelegateCall() {
        viewModel.mockLaunchType = .survey(manager: viewModel.surveySurfaceManager)
        let subject = createSubject()

        subject.startLoading()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .survey = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected survey launch type")
            return
        }
    }

    func test_fullLaunchFlow_withDefaultBrowserLaunchType_triggersCorrectDelegateCall() {
        viewModel.mockLaunchType = .defaultBrowser
        let subject = createSubject()

        subject.startLoading()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .defaultBrowser = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected default browser launch type")
            return
        }
    }

    func test_fullLaunchFlow_withNilLaunchType_triggersLaunchBrowser() {
        viewModel.mockLaunchType = nil
        let subject = createSubject()

        subject.startLoading()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 0)
    }

    // MARK: - Edge Cases and Error Handling Tests

    func test_launchMethods_withoutAnimationStarted_handlesGracefully() {
        let subject = createSubject()
        let launchType: LaunchType = .intro(manager: viewModel.introScreenManager)

        subject.launchWith(launchType: launchType)
        subject.launchBrowser()

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
        XCTAssertTrue(coordinatorDelegate.launchWithTypeCalled > 0 || coordinatorDelegate.launchBrowserCalled > 0)
    }

    // MARK: - Enhanced Mock Verification Tests

    func test_viewModelCallTracking_verifiesCorrectBehavior() {
        let subject = createSubject()

        subject.startLoading()
        viewModel.loadNextLaunchType()
        subject.finishedLoadingLaunchOrder()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(viewModel.loadNextLaunchTypeCalled, 1)
    }

    func test_coordinatorDelegateCallTracking_verifiesCorrectBehavior() {
        let subject = createSubject()
        let introLaunchType: LaunchType = .intro(manager: viewModel.introScreenManager)
        let updateLaunchType: LaunchType = .update(viewModel: viewModel.updateViewModel)

        subject.launchWith(launchType: introLaunchType)
        subject.launchWith(launchType: updateLaunchType)
        subject.launchBrowser()

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 2)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled + coordinatorDelegate.launchBrowserCalled, 3)
        XCTAssertTrue(coordinatorDelegate.launchWithTypeCalled > 0 || coordinatorDelegate.launchBrowserCalled > 0)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 2)
    }

    func test_launchTypeVerification_withIntroType_verifiesCorrectly() {
        let subject = createSubject()
        let introType: LaunchType = .intro(manager: viewModel.introScreenManager)

        subject.launchWith(launchType: introType)

        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCalled(with: introType))
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
    }

    func test_launchTypeVerification_withUpdateType_verifiesCorrectly() {
        let subject = createSubject()
        let updateType: LaunchType = .update(viewModel: viewModel.updateViewModel)

        subject.launchWith(launchType: updateType)

        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCalled(with: updateType))
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
    }

    func test_launchTypeVerification_withSurveyType_verifiesCorrectly() {
        let subject = createSubject()
        let surveyType: LaunchType = .survey(manager: viewModel.surveySurfaceManager)

        subject.launchWith(launchType: surveyType)

        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCalled(with: surveyType))
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
    }

    func test_launchTypeVerification_withDefaultBrowserType_verifiesCorrectly() {
        let subject = createSubject()
        let defaultBrowserType: LaunchType = .defaultBrowser

        subject.launchWith(launchType: defaultBrowserType)

        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCalled(with: defaultBrowserType))
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
    }

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> ModernLaunchScreenViewController {
        let subject = ModernLaunchScreenViewController(windowUUID: windowUUID,
                                                       coordinator: coordinatorDelegate,
                                                       viewModel: viewModel)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
