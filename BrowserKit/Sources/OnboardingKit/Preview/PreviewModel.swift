// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import SwiftUI
import Common

private struct PreviewModel: OnboardingCardInfoModelProtocol {
    let cardType: OnboardingCardType
    let name, title, body, a11yIdRoot, imageID: String
    let order: Int
    let instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?
    let link: OnboardingLinkInfoModel?
    let buttons: OnboardingButtons<OnboardingActions>
    let multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>]
    let onboardingType: OnboardingType
    let embededLinkText: [EmbeddedLink]

    init(
        cardType: OnboardingCardType,
        name: String,
        order: Int,
        title: String,
        body: String,
        link: OnboardingLinkInfoModel? = nil,
        buttons: OnboardingButtons<OnboardingActions>,
        multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>] = [],
        onboardingType: OnboardingType = .freshInstall,
        a11yIdRoot: String,
        imageID: String,
        instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>? = nil,
        embededLinkText: [EmbeddedLink] = []
    ) {
        self.cardType = cardType; self.name = name; self.order = order; self.title = title; self.body = body
        self.link = link; self.buttons = buttons; self.multipleChoiceButtons = multipleChoiceButtons
        self.onboardingType = onboardingType; self.a11yIdRoot = a11yIdRoot; self.imageID = imageID
        self.instructionsPopup = instructionsPopup
        self.embededLinkText = embededLinkText
    }

    var defaultSelectedButton: OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>? =
    OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>(
        title: "Bottom",
        action: OnboardingMultipleChoiceAction.toolbarBottom,
        imageID: "toolbarBottom"
    )

    var image: UIImage? { UIImage(named: imageID, in: Bundle.module, compatibleWith: nil) }
}

enum OnboardingType: String, Codable, Sendable {
    case freshInstall = "fresh-install"
    case upgrade
}

enum OnboardingMultipleChoiceAction: String, CaseIterable, Codable, Sendable {
    case themeDark = "theme-dark"
    case themeLight = "theme-light"
    case themeSystemDefault = "theme-system-default"
    case toolbarBottom = "toolbar-bottom"
    case toolbarTop = "toolbar-top"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .themeDark:
            return "Dark"
        case .themeLight:
            return "Light"
        case .themeSystemDefault:
            return "System Default"
        case .toolbarBottom:
            return "Bottom"
        case .toolbarTop:
            return "Top"
        }
    }
}

enum OnboardingInstructionsPopupActions: String, CaseIterable, Codable, Sendable {
    case dismiss
    case dismissAndNextCard = "dismiss-and-next-card"
    case openIosFxSettings = "open-ios-fx-settings"

    var displayName: String { rawValue }
    var id: String { rawValue }
}

enum OnboardingActions: String, CaseIterable, Codable, Sendable {
    case endOnboarding = "end-onboarding"
    case forwardOneCard = "forward-one-card"
    case forwardTwoCard = "forward-two-card"
    case forwardThreeCard = "forward-three-card"
    case openInstructionsPopup = "open-instructions-popup"
    case openIosFxSettings = "open-ios-fx-settings"
    case readPrivacyPolicy = "read-privacy-policy"
    case requestNotifications = "request-notifications"
    case setDefaultBrowser = "set-default-browser"
    case syncSignIn = "sync-sign-in"

    var displayName: String { rawValue }
    var id: String { rawValue }
}

extension PreviewModel {
    static let welcome = PreviewModel(
        cardType: .basic,
        name: "welcome",
        order: 10,
        title: "Say goodbye to creepy ads",
        body: "One choice protects you everywhere you go on the web. You can always change it later.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Get Started", action: OnboardingActions.forwardOneCard),
            secondary: .init(title: "Not Now", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_welcome",
        imageID: "onboardingTrackers",
        instructionsPopup: OnboardingInstructionsPopupInfoModel(
            title: "Set as Default Browser",
            instructionSteps: [
                "Open Settings",
                "Find Default Apps",
                "Select Firefox"
            ],
            buttonTitle: "Open Settings",
            buttonAction: OnboardingInstructionsPopupActions.openIosFxSettings,
            a11yIdRoot: "onboarding_welcomeInstructionsPopup"
        )
    )

    static let signToSync = PreviewModel(
        cardType: .basic,
        name: "signToSync",
        order: 20,
        title: "Instantly pick up where you left off",
        body: "Get bookmarks, tabs, and passwords on any device. All protected with encryption.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Sign In", action: OnboardingActions.syncSignIn),
            secondary: .init(title: "Skip", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_signToSync",
        imageID: "onboardingSyncWithIcons",
        instructionsPopup: nil
    )

    static let customizationToolbar = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationToolbar",
        order: 41,
        title: "Toolbar Position",
        body: "Choose where to put your address bar",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(
                title: "Top",
                action: OnboardingMultipleChoiceAction.toolbarTop,
                imageID: "onboardingToolbarIconTop"
            ),
            .init(
                title: "Bottom",
                action: OnboardingMultipleChoiceAction.toolbarBottom,
                imageID: "onboardingToolbarIconBottom"
            )
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationToolbar",
        imageID: "toolbar",
        instructionsPopup: nil
    )

    static let tos = PreviewModel(
        cardType: .basic,
        name: "tos",
        order: 20,
        title: "Upgrade your browsing",
        body: "Our fastest iOS browser yet\nAutomatic tracking protection\nSync on all your devices",
        link: nil,
        buttons: .init(
            primary: .init(title: "Agree and Continue", action: OnboardingActions.syncSignIn),
            secondary: nil
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_termsOfUse",
        imageID: "fxHomeHeaderLogoBall",
        instructionsPopup: nil,
        embededLinkText: [
            EmbeddedLink(
                fullText: "By continuing, you agree to the Firefox Terms of Use",
                linkText: "Firefox Terms of Use",
                action: .openTermsOfService
            ),
            EmbeddedLink(
                fullText: "Firefox cares about your privacy. Read more in our Privacy Notice",
                linkText: "Privacy Notice",
                action: .openPrivacyNotice
            ),
            EmbeddedLink(
                fullText:
                    "To help improve the browser, Firefox sends diagnostic and interaction data to Mozilla. Manage settings",
                linkText: "Manage settings",
                action: .openManageSettings
            )
        ]
    )
}

extension PreviewModel {
    /// All of the built-in preview cards
    static let all: [PreviewModel] = [
        .welcome,
        .customizationToolbar,
        .signToSync
    ]
}

#Preview("Onboarding Flow") {
    OnboardingView<PreviewModel>(
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
        viewModel: OnboardingFlowViewModel(
            onboardingCards: PreviewModel.all,
            skipText: "Skip",
            onActionTap: { _, _, _ in
            },
            onMultipleChoiceActionTap: { _, _ in },
            onComplete: { _ in }
        )
    )
}

#Preview("Terms of service") {
    TermsOfUseView(
        viewModel: TermsOfUseFlowViewModel(
            configuration: PreviewModel.tos,
            onTermsOfUseTap: {},
            onPrivacyNoticeTap: {},
            onManageSettingsTap: {},
            onComplete: {}
        ),
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
    )
}

#endif
