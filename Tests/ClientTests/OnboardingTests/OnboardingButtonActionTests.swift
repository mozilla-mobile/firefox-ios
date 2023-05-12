// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MockIntroViewController: OnboardingCardDelegate {
    var action: OnboardingActions?

    func handleButtonPress(
        for action: OnboardingActions,
        from cardType: IntroViewModel.InformationCards
    ) {
        switch action {
        case .syncSignIn:
            self.action = .syncSignIn
        case .requestNotifications:
            self.action = .requestNotifications
        case .nextCard:
            showNextPage(cardType)
        case .setDefaultBrowser:
            self.action = .setDefaultBrowser
        case .readPrivacyPolicy:
            showPrivacyPolicy(.welcome)
        }
    }

    func showPrivacyPolicy(_ cardType: IntroViewModel.InformationCards) {
        action = .readPrivacyPolicy
    }

    func showNextPage(_ cardType: IntroViewModel.InformationCards) {
        action = .nextCard
    }

    func pageChanged(_ cardType: IntroViewModel.InformationCards) { }
}

class OnboardingButtonActionTests: XCTestCase {
    var subject: OnboardingCardViewController!
    var mockDelegate: MockIntroViewController!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        mockDelegate = nil
    }

    func testMockDelegate_whenInitialized_actionIsNil() {
        setSubjecUpWith(firstAction: .nextCard)

        XCTAssertNil(mockDelegate.action)
    }

    func testsubject_whenOnlyOneButtonExists_secondaryButtonIsHidden() {
        setSubjecUpWith(firstAction: .nextCard, twoButtons: false)

        subject.secondaryAction()

        XCTAssertNil(mockDelegate.action)
    }

    func testsubject_primaryAction_returnsNextCardAction() {
        setSubjecUpWith(firstAction: .nextCard)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.nextCard)
    }

    func testsubject_buttonAction_returnsPrivacyPolicyAction() {
        setSubjecUpWith(firstAction: .readPrivacyPolicy)

        subject.linkButtonAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.readPrivacyPolicy)
    }

    func testsubject_buttonAction_returnsNotifiactionsAction() {
        setSubjecUpWith(firstAction: .requestNotifications)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.requestNotifications)
    }
    func testsubject_buttonAction_returnsSyncAction() {
        setSubjecUpWith(firstAction: .syncSignIn)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.syncSignIn)
    }

    func testsubject_buttonAction_returnsSetAsDefaultAction() {
        setSubjecUpWith(firstAction: .setDefaultBrowser)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.setDefaultBrowser)
    }

    // MARK: - Helpers
    func setSubjecUpWith(
        firstAction: OnboardingActions,
        twoButtons: Bool = true
    ) {
        var buttons: OnboardingButtons
        if twoButtons {
            buttons = OnboardingButtons(
                primary: OnboardingButtonInfoModel(
                    title: .Onboarding.Sync.SignInAction,
                    action: firstAction),
                secondary: OnboardingButtonInfoModel(
                    title: .Onboarding.Sync.SkipAction,
                    action: .nextCard))
        } else {
            buttons = OnboardingButtons(
                primary: OnboardingButtonInfoModel(
                    title: .Onboarding.Sync.SignInAction,
                    action: firstAction))
        }

        let mockInfoModel = OnboardingCardInfoModel(
            name: "signSync",
            title: String(format: .Onboarding.Sync.Title),
            body: String(format: .Onboarding.Sync.Description),
            link: nil,
            buttons: buttons,
            type: .freshInstall,
            a11yIdRoot: AccessibilityIdentifiers.Onboarding.signSyncCard,
            imageID: ImageIdentifiers.onboardingSyncv106)
        let mockCardViewModel = LegacyOnboardingCardViewModel(
            cardType: .welcome,
            infoModel: mockInfoModel,
            isFeatureEnabled: true)

        mockDelegate = MockIntroViewController()
        subject = OnboardingCardViewController(
            viewModel: mockCardViewModel,
            delegate: mockDelegate)
        subject.viewDidLoad()
    }
}
