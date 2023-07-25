// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class OnboardingButtonActionTests: XCTestCase {
    var mockDelegate: MockOnboardinCardDelegateController!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        mockDelegate = nil
    }

    func testMockDelegate_whenInitialized_actionIsNil() {
        _ = setSubjectUpWith(firstAction: .nextCard)

        XCTAssertNil(mockDelegate.action)
    }

    func testsubject_whenOnlyOneButtonExists_secondaryButtonIsHidden() {
        let subject = setSubjectUpWith(firstAction: .nextCard, twoButtons: false)

        subject.secondaryAction()

        XCTAssertNil(mockDelegate.action)
    }

    func testsubject_primaryAction_returnsNextCardAction() {
        let subject = setSubjectUpWith(firstAction: .nextCard)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.nextCard)
    }

    func testsubject_buttonAction_returnsPrivacyPolicyAction() {
        let subject = setSubjectUpWith(firstAction: .readPrivacyPolicy)

        subject.linkButtonAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.readPrivacyPolicy)
    }

    func testsubject_buttonAction_returnsNotifiactionsAction() {
        let subject = setSubjectUpWith(firstAction: .requestNotifications)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.requestNotifications)
    }
    func testsubject_buttonAction_returnsSyncAction() {
        let subject = setSubjectUpWith(firstAction: .syncSignIn)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.syncSignIn)
    }

    func testsubject_buttonAction_returnsSetAsDefaultAction() {
        let subject = setSubjectUpWith(firstAction: .setDefaultBrowser)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.setDefaultBrowser)
    }

    func testsubject_buttonAction_returnsOpenPopupAction() {
        let subject = setSubjectUpWith(firstAction: .openInstructionsPopup)

        subject.primaryAction()

        XCTAssertEqual(mockDelegate.action, OnboardingActions.openInstructionsPopup)
    }

    // MARK: - Helpers
    func setSubjectUpWith(
        firstAction: OnboardingActions,
        twoButtons: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) -> OnboardingCardViewController {
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
            order: 10,
            title: String(format: .Onboarding.Sync.Title),
            body: String(format: .Onboarding.Sync.Description),
            link: nil,
            buttons: buttons,
            type: .freshInstall,
            a11yIdRoot: AccessibilityIdentifiers.Onboarding.onboarding,
            imageID: ImageIdentifiers.onboardingSyncv106,
            instructionsPopup: nil)

        mockDelegate = MockOnboardinCardDelegateController()
        let subject = OnboardingCardViewController(
            viewModel: mockInfoModel,
            delegate: mockDelegate)

        trackForMemoryLeaks(subject, file: file, line: line)

        subject.viewDidLoad()

        return subject
    }
}
