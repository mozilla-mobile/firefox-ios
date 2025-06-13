// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import OnboardingKit
@testable import Client

// MARK: - Mock Classes

class MockOnboardingServiceDelegate: OnboardingServiceDelegate {
    var presentCalled = false
    var dismissCalled = false
    var presentedViewController: UIViewController?
    var animatedValue: Bool?
    var completionCalled = false

    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentCalled = true
        presentedViewController = viewController
        animatedValue = animated
        completion?()
        completionCalled = true
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        dismissCalled = true
        animatedValue = animated
        completion?()
        completionCalled = true
    }
}

class MockOnboardingNavigationDelegate: OnboardingNavigationDelegate {
    var finishOnboardingFlowCalled = false

    func finishOnboardingFlow() {
        finishOnboardingFlowCalled = true
    }
}

final class MockIntroScreenManager: IntroScreenManagerProtocol {
    /// Controls what `shouldShowIntroScreen` returns
    var stubShouldShowIntroScreen: Bool

    /// Controls what `isModernOnboardingEnabled` returns
    var stubIsModernOnboardingEnabled: Bool

    /// Records whether `didSeeIntroScreen()` was invoked
    var didSeeIntroScreenCalled = false

    init(
        shouldShowIntro: Bool = false,
        isModernEnabled: Bool = false
    ) {
        self.stubShouldShowIntroScreen = shouldShowIntro
        self.stubIsModernOnboardingEnabled = isModernEnabled
    }

    var shouldShowIntroScreen: Bool {
        return stubShouldShowIntroScreen
    }

    var isModernOnboardingEnabled: Bool {
        return stubIsModernOnboardingEnabled
    }

    func didSeeIntroScreen() {
        didSeeIntroScreenCalled = true
    }
}

class MockSearchBarLocationSaver: SearchBarLocationSaverProtocol {
    var saveUserSearchBarLocationCalled = false
    var savedProfile: Profile?

    func saveUserSearchBarLocation(profile: Profile, userInterfaceIdiom: UIUserInterfaceIdiom) {
        saveUserSearchBarLocationCalled = true
        savedProfile = profile
    }
}

class MockActivityEventHelper: ActivityEventHelper {
    var chosenOption: [IntroViewModel.OnboardingOptions] = []
    var updateOnboardingUserActivationEventCalled = false

    override func updateOnboardingUserActivationEvent() {
        updateOnboardingUserActivationEventCalled = true
    }
}

// MARK: - Test Class

final class OnboardingServiceTests: XCTestCase {
    var sut: OnboardingService!
    var mockDelegate: MockOnboardingServiceDelegate!
    var mockNavigationDelegate: MockOnboardingNavigationDelegate!
    var mockUserDefaults: MockUserDefaults!
    var mockNotificationManager: MockNotificationManager!
    var mockDefaultApplicationHelper: MockApplicationHelper!
    var mockNotificationCenter: MockNotificationCenter!
    var mockSearchBarLocationSaver: MockSearchBarLocationSaver!
    var mockProfile: MockProfile!
    var mockThemeManager: MockThemeManager!

    override func setUp() {
        super.setUp()

        mockDelegate = MockOnboardingServiceDelegate()
        mockNavigationDelegate = MockOnboardingNavigationDelegate()
        mockUserDefaults = MockUserDefaults()
        mockNotificationManager = MockNotificationManager()
        mockDefaultApplicationHelper = MockApplicationHelper()
        mockNotificationCenter = MockNotificationCenter()
        mockSearchBarLocationSaver = MockSearchBarLocationSaver()
        mockProfile = MockProfile(databasePrefix: "OnboardingServiceTests")
        mockThemeManager = MockThemeManager()

        sut = OnboardingService(
            userDefaults: mockUserDefaults,
            windowUUID: .DefaultUITestingUUID,
            profile: mockProfile,
            themeManager: mockThemeManager,
            delegate: mockDelegate,
            navigationDelegate: mockNavigationDelegate,
            qrCodeNavigationHandler: nil,
            notificationManager: mockNotificationManager,
            defaultApplicationHelper: mockDefaultApplicationHelper,
            notificationCenter: mockNotificationCenter,
            searchBarLocationSaver: mockSearchBarLocationSaver
        )
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        sut = nil
        mockDelegate = nil
        mockNavigationDelegate = nil
        mockUserDefaults = nil
        mockNotificationManager = nil
        mockDefaultApplicationHelper = nil
        mockNotificationCenter = nil
        mockSearchBarLocationSaver = nil
        mockProfile = nil
        mockThemeManager = nil
        super.tearDown()
    }

    // MARK: - Request Notifications Tests

    func testHandleAction_RequestNotifications_CallsNotificationManager() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let expectation = XCTestExpectation(description: "Completion called")

        // When
        sut.handleAction(
            .requestNotifications,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { result in
            expectation.fulfill()
        }

        // Then
        XCTAssertTrue(mockNotificationManager.requestAuthorizationCalled)
        XCTAssertTrue(activityEventHelper.chosenOptions.contains(.askForNotificationPermission))
        XCTAssertTrue(activityEventHelper.updateOnboardingUserActivationEventCalled)

        wait(for: [expectation], timeout: 1.0)
    }

    func testAskForNotificationPermission_GrantedPermission_SetsUserDefaults() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        mockNotificationManager.shouldGrantPermission = true
        let expectation = XCTestExpectation(description: "Async completion")

        // When
        sut.handleAction(
            .requestNotifications,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { _ in }

        // Wait for async completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(mockUserDefaults.setCalledCount > 0)
        XCTAssertTrue(mockNotificationCenter.postCallCount > 0)
        XCTAssertEqual(mockNotificationCenter.savePostName, .RegisterForPushNotifications)
    }

    func testAskForNotificationPermission_DeniedPermission_DoesNotSetUserDefaults() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        mockNotificationManager.shouldGrantPermission = false
        let expectation = XCTestExpectation(description: "Async completion")

        // When
        sut.handleAction(
            .requestNotifications,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { _ in }

        // Wait for async completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertFalse(mockNotificationCenter.postCallCount > 0)
    }

    // MARK: - Forward Card Tests

    func testHandleAction_ForwardOneCard_ReturnsCorrectTabAction() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let expectation = XCTestExpectation(description: "Completion called")
        var resultTabAction: OnboardingFlowViewModel<OnboardingKitCardInfoModel>.TabAction?

        // When
        sut.handleAction(
            .forwardOneCard,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { result in
            if case .success(let tabAction) = result {
                resultTabAction = tabAction
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        if case .advance(let numberOfPages) = resultTabAction {
            XCTAssertEqual(numberOfPages, 1)
        } else {
            XCTFail("Expected advance tab action with 1 page")
        }
    }

    func testHandleAction_ForwardTwoCard_ReturnsCorrectTabAction() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let expectation = XCTestExpectation(description: "Completion called")
        var resultTabAction: OnboardingFlowViewModel<OnboardingKitCardInfoModel>.TabAction?

        // When
        sut.handleAction(
            .forwardTwoCard,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { result in
            if case .success(let tabAction) = result {
                resultTabAction = tabAction
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        if case .advance(let numberOfPages) = resultTabAction {
            XCTAssertEqual(numberOfPages, 2)
        } else {
            XCTFail("Expected advance tab action with 2 pages")
        }
    }

    func testHandleAction_ForwardThreeCard_ReturnsCorrectTabAction() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let expectation = XCTestExpectation(description: "Completion called")
        var resultTabAction: OnboardingFlowViewModel<OnboardingKitCardInfoModel>.TabAction?

        // When
        sut.handleAction(
            .forwardThreeCard,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { result in
            if case .success(let tabAction) = result {
                resultTabAction = tabAction
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        if case .advance(let numberOfPages) = resultTabAction {
            XCTAssertEqual(numberOfPages, 3)
        } else {
            XCTFail("Expected advance tab action with 3 pages")
        }
    }

    // MARK: - Sync Sign In Tests

    func testHandleAction_SyncSignIn_UpdatesActivityEventHelper() {
        // Given
        let activityEventHelper = MockActivityEventHelper()

        // When
        sut.handleAction(
            .syncSignIn,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { _ in }

        // Then
        XCTAssertTrue(activityEventHelper.chosenOptions.contains(.syncSignIn))
        XCTAssertTrue(activityEventHelper.updateOnboardingUserActivationEventCalled)
        XCTAssertTrue(mockDelegate.presentCalled)
        XCTAssertNotNil(mockDelegate.presentedViewController)
        XCTAssertEqual(mockDelegate.animatedValue, true)
    }

    // MARK: - Set Default Browser Tests

    func testHandleAction_SetDefaultBrowser_OpensSettings() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let expectation = XCTestExpectation(description: "Completion called")

        // When
        sut.handleAction(
            .setDefaultBrowser,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(activityEventHelper.chosenOptions.contains(.setAsDefaultBrowser))
        XCTAssertTrue(activityEventHelper.updateOnboardingUserActivationEventCalled)
        XCTAssertTrue(mockDefaultApplicationHelper.openSettingsCalled > 0)
    }

    // MARK: - Open iOS Fx Settings Tests

    func testHandleAction_OpenIosFxSettings_OpensSettings() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let expectation = XCTestExpectation(description: "Completion called")

        // When
        sut.handleAction(
            .openIosFxSettings,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(mockDefaultApplicationHelper.openSettingsCalled > 0)
    }

    // MARK: - End Onboarding Tests

    func testHandleAction_EndOnboarding_CallsRequiredMethods() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let expectation = XCTestExpectation(description: "Completion called")

        // When
        sut.handleAction(
            .endOnboarding,
            from: "testCard",
            cards: [],
            with: activityEventHelper
        ) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(mockSearchBarLocationSaver.saveUserSearchBarLocationCalled)
//        XCTAssertEqual((mockSearchBarLocationSaver.savedProfile as? MockProfile)., mockProfile)
        XCTAssertTrue(mockNavigationDelegate.finishOnboardingFlowCalled)
    }

    // MARK: - Read Privacy Policy Tests

    func testHandleAction_ReadPrivacyPolicy_WithValidURL_PresentsViewController() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let testURL = URL(string: "https://example.com/privacy")!
        let mockCard = createMockCard(name: "testCard", url: testURL)

        // When
        sut.handleAction(
            .readPrivacyPolicy,
            from: "testCard",
            cards: [mockCard],
            with: activityEventHelper
        ) { _ in }

        // Then
        XCTAssertTrue(mockDelegate.presentCalled)
        XCTAssertNotNil(mockDelegate.presentedViewController)
        XCTAssertEqual(mockDelegate.animatedValue, true)
    }

    func testHandleAction_ReadPrivacyPolicy_WithInvalidCard_DoesNotPresentViewController() {
        // Given
        let activityEventHelper = MockActivityEventHelper()
        let expectation = XCTestExpectation(description: "Completion called")

        // When
        sut.handleAction(
            .readPrivacyPolicy,
            from: "nonExistentCard",
            cards: [],
            with: activityEventHelper
        ) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertFalse(mockDelegate.presentCalled)
    }

    // MARK: - Helper Methods

    private func createMockCard(name: String, url: URL?) -> OnboardingKitCardInfoModel {
        let linkModel = url != nil ? OnboardingKit.OnboardingLinkInfoModel(title: "Link", url: url!) : nil
        return OnboardingKitCardInfoModel(
            cardType: .multipleChoice,
            name: name,
            order: 41,
            title: "Toolbar Position",
            body: "Where should the toolbar appear?",
            link: linkModel,
            buttons: .init(
                primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
                secondary: nil
            ),
            multipleChoiceButtons: [
                .init(title: "Top", action: OnboardingMultipleChoiceAction.toolbarTop, imageID: "toolbarTop"),
                .init(title: "Bottom", action: OnboardingMultipleChoiceAction.toolbarBottom, imageID: "toolbarBottom")
            ],
            onboardingType: .freshInstall,
            a11yIdRoot: "onboarding_customizationToolbar",
            imageID: "toolbar",
            instructionsPopup: nil
        )
    }
}
