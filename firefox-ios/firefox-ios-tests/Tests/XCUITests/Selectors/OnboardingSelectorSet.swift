// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol OnboardingSelectorsSet {
    func titleLabel(rootId: String) -> Selector
    func descriptionLabel(rootId: String) -> Selector
    func primaryButton(rootId: String) -> Selector
    func secondaryButton(rootId: String) -> Selector
    func betaPrimaryButton(screenIndex: Int) -> Selector
    func betaSecondaryButton(screenIndex: Int) -> Selector
    func multipleChoiceButton(rootId: String) -> Selector
    func modernTosPrimaryButton() -> Selector
    var AGREE_AND_CONTINUE_BUTTON: Selector { get }
    var CONTINUE_BUTTON: Selector { get }
    var MANAGE_TEXT_BUTTON: Selector { get }
    var QR_SIGN_IN_BUTTON: Selector { get }
    var EMAIL_SIGN_IN_BUTTON: Selector { get }
    var DONE_BUTTON: Selector { get }
    var CLOSE_BUTTON: Selector { get }
    var NAVBAR_SYNC_AND_SAVE: Selector { get }
    var CLOSE_TOUR_BUTTON: Selector { get }
    var PAGE_CONTROL: Selector { get }
    var all: [Selector] { get }
}

struct OnboardingSelectors: OnboardingSelectorsSet {
    private enum IDs {
        static let termsAndService_AgreeAndContinueButton = "TermsOfService.AgreeAndContinueButton"
        static let continueButton = "Continue"
        static let manage_Text = "TermsOfService.ManageDataCollectionAgreement"
        static let QRCode_SignIn = "QRCodeSignIn.button"
        static let emailSignIn = "EmailSignIn.button"
        static let doneButton = "Done"
        static let closeButton = "CloseButton"
        static let syncAndSaveData = "Sync and Save Data"
        static let closeTourButton = AccessibilityIdentifiers.Onboarding.closeButton
        static let pageControl = AccessibilityIdentifiers.Onboarding.pageControl
    }

    let AGREE_AND_CONTINUE_BUTTON = Selector.buttonId(
        IDs.termsAndService_AgreeAndContinueButton,
        description: "Agree & Continue button on first onboarding screen",
        groups: ["onboarding"]
    )

    let CONTINUE_BUTTON = Selector.buttonByLabel(
        IDs.continueButton,
        description: "Continue button on first screen for Firefox/Firefox Beta",
        groups: ["onboarding"]
    )

    let MANAGE_TEXT_BUTTON = Selector.buttonId(
        IDs.manage_Text,
        description: "Help improve button on first onboarding screen",
        groups: ["onboarding"]
    )

    func titleLabel(rootId: String) -> Selector {
        Selector.staticTextId(
            "\(rootId)TitleLabel",
            description: "Dynamic title label for onboarding screen \(rootId)",
            groups: ["onboarding"]
        )
    }

    func descriptionLabel(rootId: String) -> Selector {
        Selector.staticTextId(
            "\(rootId)DescriptionLabel",
            description: "Dynamic description label for onboarding screen \(rootId)",
            groups: ["onboarding"]
        )
    }

    func primaryButton(rootId: String) -> Selector {
        Selector.buttonId(
            "\(rootId)PrimaryButton",
            description: "Dynamic primary button for onboarding screen \(rootId)",
            groups: ["onboarding"]
        )
    }

    func secondaryButton(rootId: String) -> Selector {
        Selector.buttonId(
            "\(rootId)SecondaryButton",
            description: "Dynamic secondary button for onboarding screen \(rootId)",
            groups: ["onboarding"]
        )
    }

    func betaPrimaryButton(screenIndex: Int) -> Selector {
        Selector.buttonId(
            "onboarding.\(screenIndex)PrimaryButton",
            description: "Beta-specific primary button for screen \(screenIndex)",
            groups: ["onboarding", "beta"]
        )
    }

    func betaSecondaryButton(screenIndex: Int) -> Selector {
        Selector.buttonId(
            "onboarding.\(screenIndex)SecondaryButton",
            description: "Beta-specific secondary button for screen \(screenIndex)",
            groups: ["onboarding", "beta"]
        )
    }

    let QR_SIGN_IN_BUTTON = Selector.buttonId(
        IDs.QRCode_SignIn,
        description: "QR Code Sign-In button",
        groups: ["onboarding", "signin"]
    )

    let EMAIL_SIGN_IN_BUTTON = Selector.buttonId(
        IDs.emailSignIn,
        description: "Email Sign-In button",
        groups: ["onboarding", "signin"]
    )

    let DONE_BUTTON = Selector.buttonByLabel(
        IDs.doneButton,
        description: "Done button on Sign-In screen",
        groups: ["onboarding"]
    )

    let CLOSE_BUTTON = Selector.buttonByLabel(
        IDs.closeButton,
        description: "Close button to dismiss onboarding flow",
        groups: ["onboarding"]
    )

    let NAVBAR_SYNC_AND_SAVE = Selector.navigationBarId(
        IDs.syncAndSaveData,
        description: "Navbar title in Sign-In screen",
        groups: ["onboarding"]
    )

    let CLOSE_TOUR_BUTTON = Selector.buttonId(
        IDs.closeTourButton,
        description: "Close button to dismiss onboarding tour",
        groups: ["onboarding"]
    )

    func multipleChoiceButton(rootId: String) -> Selector {
        Selector.buttonId(
            "\(rootId)MultipleChoiceButton",
            description: "Multiple choice button for onboarding screen \(rootId)",
            groups: ["onboarding", "modern"]
        )
    }

    func modernTosPrimaryButton() -> Selector {
        Selector.buttonId(
            "\(AccessibilityIdentifiers.TermsOfService.root)PrimaryButton",
            description: "Modern Terms of Service primary button",
            groups: ["onboarding", "modern"]
        )
    }

    let PAGE_CONTROL = Selector.pageIndicatorById(
        IDs.pageControl,
        description: "Page control indicator showing onboarding progress",
        groups: ["onboarding"]
    )

    var all: [Selector] {
        [AGREE_AND_CONTINUE_BUTTON, CONTINUE_BUTTON, MANAGE_TEXT_BUTTON, QR_SIGN_IN_BUTTON, EMAIL_SIGN_IN_BUTTON,
         DONE_BUTTON, CLOSE_BUTTON, NAVBAR_SYNC_AND_SAVE, CLOSE_TOUR_BUTTON, PAGE_CONTROL]
    }
}
