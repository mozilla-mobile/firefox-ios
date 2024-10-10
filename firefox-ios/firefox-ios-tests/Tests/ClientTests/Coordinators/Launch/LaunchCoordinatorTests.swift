// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

final class LaunchCoordinatorTests: XCTestCase {
    private var profile: MockProfile!
    private var mockRouter: MockRouter!
    private var delegate: MockLaunchCoordinatorDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        mockRouter = MockRouter(navigationController: MockNavigationController())
        delegate = MockLaunchCoordinatorDelegate()
    }

    override func tearDown() {
        profile = nil
        mockRouter = nil
        delegate = nil
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testInitialState() {
        let subject = createSubject(isIphone: true)

        XCTAssertEqual(mockRouter.presentCalled, 0)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    // MARK: - Intro
    func testStart_introNotIphone_present() throws {
        let introScreenManager = IntroScreenManager(prefs: profile.prefs)
        let subject = createSubject(isIphone: false)
        subject.start(with: .intro(manager: introScreenManager))

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        let presentedViewController = try XCTUnwrap(mockRouter.presentedViewController)
        XCTAssertNotNil(presentedViewController as? IntroViewController)
    }

    func testStart_introIsIphone_setRootView() throws {
        let introScreenManager = IntroScreenManager(prefs: profile.prefs)
        let subject = createSubject(isIphone: true)
        subject.start(with: .intro(manager: introScreenManager))

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        let pushedVC = try XCTUnwrap(mockRouter.presentedViewController)
        XCTAssertNotNil(pushedVC as? IntroViewController)
    }

    // MARK: - Update
    func testStart_updateNotIphone_present() throws {
        let onboardingModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        let viewModel = UpdateViewModel(profile: profile,
                                        model: onboardingModel,
                                        telemetryUtility: telemetryUtility,
                                        windowUUID: windowUUID)
        let subject = createSubject(isIphone: false)
        subject.start(with: .update(viewModel: viewModel))

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        let presentedViewController = try XCTUnwrap(mockRouter.presentedViewController)
        XCTAssertNotNil(presentedViewController as? UpdateViewController)
    }

    func testStart_updateIsIphone_setRootView() throws {
        let onboardingModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        let viewModel = UpdateViewModel(profile: profile,
                                        model: onboardingModel,
                                        telemetryUtility: telemetryUtility,
                                        windowUUID: windowUUID)
        let subject = createSubject(isIphone: true)
        subject.start(with: .update(viewModel: viewModel))

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        let pushedVC = try XCTUnwrap(mockRouter.presentedViewController)
        XCTAssertNotNil(pushedVC as? UpdateViewController)
    }

    // MARK: - Default browser
    func testStart_defaultBrowser_present() throws {
        let subject = createSubject(isIphone: false)
        subject.start(with: .defaultBrowser)

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        let presentedViewController = try XCTUnwrap(mockRouter.presentedViewController)
        XCTAssertNotNil(presentedViewController as? DefaultBrowserOnboardingViewController)
    }

    // MARK: - Survey
    func testStart_surveyNoMessage_completes() throws {
        let manager = SurveySurfaceManager(windowUUID: windowUUID)
        let subject = createSubject(isIphone: false)
        subject.start(with: .survey(manager: manager))

        XCTAssertEqual(mockRouter.presentCalled, 0)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        XCTAssertNil(mockRouter.presentedViewController)
    }

    func testStart_surveyWithMessage_setRootView() throws {
        let messageManager = MockGleanPlumbMessageManagerProtocol()
        let message = createMessage(isExpired: false)
        messageManager.message = message
        let manager = SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)
        XCTAssertTrue(manager.shouldShowSurveySurface)

        let subject = createSubject(isIphone: false)
        subject.start(with: .survey(manager: manager))

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
        let pushedVC = try XCTUnwrap(mockRouter.presentedViewController)
        XCTAssertNotNil(pushedVC as? SurveySurfaceViewController)
    }

    // MARK: - QRCodeNavigationHandler

    func testShowQRCode_addsChildQRCodeCoordinator() {
        let subject = createSubject(isIphone: true)
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is QRCodeCoordinator)
    }

    func testShowQRCode_presentsQRCodeNavigationController() {
        let subject = createSubject(isIphone: true)
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is QRCodeNavigationController)
    }

    // MARK: - Delegates
    func testStart_surveySetsDelegate() throws {
        let messageManager = MockGleanPlumbMessageManagerProtocol()
        let message = createMessage(isExpired: false)
        messageManager.message = message
        let manager = SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)
        XCTAssertTrue(manager.shouldShowSurveySurface)

        let subject = createSubject(isIphone: false)
        subject.start(with: .survey(manager: manager))

        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? SurveySurfaceViewController)
        XCTAssertNotNil(presentedVC.delegate)
    }

    func testDidFinish_fromSurveySurfaceViewControllerDelegate() {
        let subject = createSubject(isIphone: false)
        subject.parentCoordinator = delegate
        subject.didFinish()

        XCTAssertEqual(delegate.didFinishCalledCount, 1)
        XCTAssertEqual(delegate.savedDidFinishCoordinator?.id, subject.id)
    }

    // MARK: - Helpers
    private func createSubject(isIphone: Bool,
                               file: StaticString = #file,
                               line: UInt = #line) -> LaunchCoordinator {
        let subject = LaunchCoordinator(
            router: mockRouter,
            windowUUID: .XCTestDefaultUUID,
            profile: profile,
            isIphone: isIphone
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createMessage(
        for surface: MessageSurfaceId = .survey,
        isExpired: Bool
    ) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: isExpired)

        return GleanPlumbMessage(id: "12345",
                                 data: MockSurveyMessageDataProtocol(surface: surface),
                                 action: "https://mozilla.com",
                                 triggerIfAll: [],
                                 exceptIfAny: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }
}
