// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

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
        setSubjectUpWith(firstAction: .nextCard)

        XCTAssertNil(mockDelegate.action)
    }

    func testsubject_whenOnlyOneButtonExists_secondaryButtonIsHidden() {
        setSubjectUpWith(firstAction: .nextCard, twoButtons: false)

        subject.secondaryAction()

        XCTAssertNil(mockDelegate.action)
    }

    func testsubject_primaryAction_returnsNextCardAction() {
        setSubjectUpWith(firstAction: .nextCard)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.nextCard)
    }

    func testsubject_buttonAction_returnsPrivacyPolicyAction() {
        setSubjectUpWith(firstAction: .readPrivacyPolicy)

        subject.linkButtonAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.readPrivacyPolicy)
    }

    func testsubject_buttonAction_returnsNotifiactionsAction() {
        setSubjectUpWith(firstAction: .requestNotifications)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.requestNotifications)
    }
    func testsubject_buttonAction_returnsSyncAction() {
        setSubjectUpWith(firstAction: .syncSignIn)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.syncSignIn)
    }

    func testsubject_buttonAction_returnsSetAsDefaultAction() {
        setSubjectUpWith(firstAction: .setDefaultBrowser)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.setDefaultBrowser)
    }

    // MARK: - Helpers
    func setSubjectUpWith(
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
        trackForMemoryLeaks(subject)

        subject.viewDidLoad()
    }
}
