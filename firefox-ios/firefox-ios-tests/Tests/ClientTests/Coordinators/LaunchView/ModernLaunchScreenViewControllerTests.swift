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
    private var profile: MockProfile!
    private var coordinatorDelegate: MockLaunchFinishedLoadingDelegate!
    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    // MARK: - Test Setup & Teardown
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)

        viewModel = MockLaunchScreenViewModel(windowUUID: windowUUID, profile: MockProfile())
        coordinatorDelegate = MockLaunchFinishedLoadingDelegate()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        viewModel?.reset()
        coordinatorDelegate?.reset()
        viewModel = nil
        profile = nil
        coordinatorDelegate = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_setsPrefersStatusBarHiddenToTrue() {
        let subject = createModernSubject()
        XCTAssertTrue(subject.prefersStatusBarHidden)
    }

    // MARK: - View Lifecycle Tests

    func test_viewDidLoad_setsBackgroundColorToSystemBackground() {
        let subject = createModernSubject()
        _ = subject.view
        XCTAssertEqual(subject.view.backgroundColor, .systemBackground)
    }

    func test_viewDidLoad_triggersViewModelStartLoadingOnce() {
        let subject = createModernSubject()

        let initialLoadingCount = viewModel.startLoadingCalled
        _ = subject.view

        XCTAssertGreaterThan(
            viewModel.startLoadingCalled,
            initialLoadingCount,
            "viewDidLoad should trigger startLoading"
        )
        XCTAssertEqual(subject.view.backgroundColor, .systemBackground)
        XCTAssertNotNil(subject.children.first)
    }

    func test_viewWillAppear_whenLoading_defersLoadNextLaunchType() {
        let subject = createModernSubject()

        subject.viewDidLoad()
        let initialLoadingCount = viewModel.startLoadingCalled

        subject.viewWillAppear(false)

        XCTAssertEqual(viewModel.startLoadingCalled, initialLoadingCount)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 0)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 0)
    }

    func test_viewWillAppear_whenLoadingThenFinished_triggersDeferredLoadNextLaunchType() {
        let subject = createModernSubject()
        _ = subject.view
        subject.viewWillAppear(false)

        subject.finishedLoadingLaunchOrder()

        let expectation = expectation(description: "Deferred launch should trigger after loading completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            XCTAssertTrue(self.coordinatorDelegate.launchWithTypeCalled > 0 || self.coordinatorDelegate.launchBrowserCalled > 0)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.3)
    }

    // MARK: - Loading State Management Tests

    func test_startLoading_triggersViewModelStartLoadingOnce() {
        let subject = createModernSubject()

        let initialLoadingCount = viewModel.startLoadingCalled
        subject.startLoading()

        XCTAssertEqual(viewModel.startLoadingCalled, initialLoadingCount + 1)
    }


    // MARK: - LaunchFinishedLoadingDelegate Tests

    func test_launchWithLaunchType_callsCoordinatorDelegate() {
        let subject = createModernSubject()
        let launchType: LaunchType = .intro(manager: viewModel.introScreenManager)

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .intro = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected intro launch type")
            return
        }
    }

    func test_launchWithLaunchType_withUpdateType_callsCoordinatorCorrectly() {
        let subject = createModernSubject()
        let launchType: LaunchType = .update(viewModel: viewModel.updateViewModel)

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .update = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected update launch type")
            return
        }
    }

    func test_launchWithLaunchType_withSurveyType_callsCoordinatorCorrectly() {
        let subject = createModernSubject()
        let launchType: LaunchType = .survey(manager: viewModel.surveySurfaceManager)

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .survey = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected survey launch type")
            return
        }
    }

    func test_launchWithLaunchType_withDefaultBrowserType_callsCoordinatorCorrectly() {
        let subject = createModernSubject()
        let launchType: LaunchType = .defaultBrowser

        subject.launchWith(launchType: launchType)

        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .defaultBrowser = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected default browser launch type")
            return
        }
    }

    func test_launchBrowser_callsCoordinatorDelegate() {
        let subject = createModernSubject()

        subject.launchBrowser()

        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
    }

    // MARK: - Integration Tests

    func test_fullLaunchFlow_withIntroLaunchType_triggersCorrectDelegateCall() {
        viewModel.mockLaunchType = .intro(manager: viewModel.introScreenManager)
        let subject = createModernSubject()

        _ = subject.view
        subject.viewWillAppear(false)
        subject.viewDidAppear(false)

        subject.finishedLoadingLaunchOrder()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .intro = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected intro launch type")
            return
        }
    }

    func test_fullLaunchFlow_withUpdateLaunchType_triggersCorrectDelegateCall() {
        viewModel.mockLaunchType = .update(viewModel: viewModel.updateViewModel)
        let subject = createModernSubject()

        _ = subject.view
        subject.viewWillAppear(false)
        subject.viewDidAppear(false)

        subject.finishedLoadingLaunchOrder()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .update = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected update launch type")
            return
        }
    }

    func test_fullLaunchFlow_withSurveyLaunchType_triggersCorrectDelegateCall() {
        viewModel.mockLaunchType = .survey(manager: viewModel.surveySurfaceManager)
        let subject = createModernSubject()

        _ = subject.view
        subject.viewWillAppear(false)
        subject.viewDidAppear(false)

        subject.finishedLoadingLaunchOrder()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .survey = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected survey launch type")
            return
        }
    }

    func test_fullLaunchFlow_withDefaultBrowserLaunchType_triggersCorrectDelegateCall() {
        viewModel.mockLaunchType = .defaultBrowser
        let subject = createModernSubject()

        _ = subject.view
        subject.viewWillAppear(false)
        subject.viewDidAppear(false)

        subject.finishedLoadingLaunchOrder()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 1)
        guard case .defaultBrowser = coordinatorDelegate.savedLaunchType else {
            XCTFail("Expected default browser launch type")
            return
        }
    }

    func test_fullLaunchFlow_withNilLaunchType_triggersLaunchBrowser() {
        viewModel.mockLaunchType = nil
        let subject = createModernSubject()

        _ = subject.view
        subject.viewWillAppear(false)
        subject.viewDidAppear(false)

        subject.finishedLoadingLaunchOrder()

        XCTAssertEqual(viewModel.startLoadingCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchBrowserCalled, 1)
        XCTAssertEqual(coordinatorDelegate.launchWithTypeCalled, 0)
    }

    // MARK: - Edge Cases and Error Handling Tests

    func test_launchMethods_withoutAnimationStarted_handlesGracefully() {
        let subject = createModernSubject()
        let launchType: LaunchType = .intro(manager: viewModel.introScreenManager)

        subject.launchWith(launchType: launchType)
        subject.launchBrowser()

        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCallCount(1))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchBrowserCallCount(1))
        XCTAssertTrue(coordinatorDelegate.hasAnyLaunchBeenCalled)
    }

    // MARK: - Enhanced Mock Verification Tests

    func test_viewModelCallTracking_verifiesCorrectBehavior() {
        let subject = createModernSubject()

        subject.startLoading()
        subject.finishedLoadingLaunchOrder()

        XCTAssertTrue(viewModel.verifyStartLoadingCallCount(1))
        XCTAssertTrue(viewModel.verifyLoadNextLaunchTypeCallCount(0))

        subject.viewWillAppear(false)

        let expectation = expectation(description: "Load next launch type should be called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            XCTAssertTrue(self.viewModel.verifyLoadNextLaunchTypeCallCount(1))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.3)
    }

    func test_coordinatorDelegateCallTracking_verifiesCorrectBehavior() {
        let subject = createModernSubject()
        let introLaunchType: LaunchType = .intro(manager: viewModel.introScreenManager)
        let updateLaunchType: LaunchType = .update(viewModel: viewModel.updateViewModel)

        subject.launchWith(launchType: introLaunchType)
        subject.launchWith(launchType: updateLaunchType)
        subject.launchBrowser()

        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCallCount(2))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchBrowserCallCount(1))
        XCTAssertEqual(coordinatorDelegate.totalLaunchCalls, 3)
        XCTAssertTrue(coordinatorDelegate.hasAnyLaunchBeenCalled)
        XCTAssertEqual(coordinatorDelegate.allLaunchTypes.count, 2)
    }

    func test_mockResetFunctionality_ensuresCleanState() {
        let subject = createModernSubject()
        let launchType: LaunchType = .intro(manager: viewModel.introScreenManager)

        subject.startLoading()
        subject.launchWith(launchType: launchType)
        subject.launchBrowser()

        XCTAssertTrue(viewModel.verifyStartLoadingCallCount(1))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCallCount(1))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchBrowserCallCount(1))

        viewModel.reset()
        coordinatorDelegate.reset()

        XCTAssertTrue(viewModel.verifyStartLoadingCallCount(0))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCallCount(0))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchBrowserCallCount(0))
        XCTAssertFalse(coordinatorDelegate.hasAnyLaunchBeenCalled)
    }

    func test_launchTypeVerification_withDifferentTypes() {
        let subject = createModernSubject()
        let introType: LaunchType = .intro(manager: viewModel.introScreenManager)
        let updateType: LaunchType = .update(viewModel: viewModel.updateViewModel)
        let surveyType: LaunchType = .survey(manager: viewModel.surveySurfaceManager)
        let defaultBrowserType: LaunchType = .defaultBrowser

        subject.launchWith(launchType: introType)
        subject.launchWith(launchType: updateType)
        subject.launchWith(launchType: surveyType)
        subject.launchWith(launchType: defaultBrowserType)

        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCalled(with: introType))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCalled(with: updateType))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCalled(with: surveyType))
        XCTAssertTrue(coordinatorDelegate.verifyLaunchWithCalled(with: defaultBrowserType))
        XCTAssertEqual(coordinatorDelegate.allLaunchTypes.count, 4)
    }

    private func createModernSubject(file: StaticString = #filePath,
                                     line: UInt = #line) -> ModernLaunchScreenViewController {
        let subject = ModernLaunchScreenViewController(windowUUID: windowUUID,
                                                       coordinator: coordinatorDelegate,
                                                       viewModel: viewModel)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
