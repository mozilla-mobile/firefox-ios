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
        imageID: "onboardingToolbarIconBottom"
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
    // MARK: - Brand Refresh Flow (v148)
    static let welcomeBrandRefresh = PreviewModel(
        cardType: .basic,
        name: "welcomeBrandRefresh",
        order: 10,
        title: "Open your links with built-in privacy",
        body: "We protect your data and automatically block companies from spying on your clicks.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Set as Default Browser", action: OnboardingActions.openInstructionsPopup),
            secondary: .init(title: "Not Now", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_welcome",
        imageID: "onboardingTrackersBrandRefresh",
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

    static let customizationToolbarBrandRefresh = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationToolbarBrandRefresh",
        order: 20,
        title: "Choose your address bar",
        body: "Start typing to get search suggestions, your top sites, bookmarks, " +
            "history and search engines — all in one place.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(
                title: "Bottom",
                action: OnboardingMultipleChoiceAction.toolbarBottom,
                imageID: "onboardingToolbarIconBottomJapan"
            ),
            .init(
                title: "Top",
                action: OnboardingMultipleChoiceAction.toolbarTop,
                imageID: "onboardingToolbarIconTopJapan"
            )
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationToolbar",
        imageID: "toolbar",
        instructionsPopup: nil
    )

    static let customizationThemeBrandRefresh = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationThemeBrandRefresh",
        order: 25,
        title: "Pick your theme",
        body: "Pick your favorite theme or have Firefox match your device, putting you in control.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(
                title: "Automatic",
                action: OnboardingMultipleChoiceAction.themeSystemDefault,
                imageID: "onboardingThemeSystemJapan"
            ),
            .init(
                title: "Light",
                action: OnboardingMultipleChoiceAction.themeLight,
                imageID: "onboardingThemeLightJapan"
            ),
            .init(
                title: "Dark",
                action: OnboardingMultipleChoiceAction.themeDark,
                imageID: "onboardingThemeDarkJapan"
            )
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationTheme",
        imageID: "themeing",
        instructionsPopup: nil
    )

    static let signToSyncBrandRefresh = PreviewModel(
        cardType: .basic,
        name: "signToSyncBrandRefresh",
        order: 30,
        title: "Instantly pick up where you left off",
        body: "Grab bookmarks, passwords, and more on any device in a snap. " +
            "Your personal data stays safe and secure with encryption.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Start Syncing", action: OnboardingActions.syncSignIn),
            secondary: .init(title: "Not Now", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_signToSync",
        imageID: "onboardingSyncWithIconsBrandRefresh",
        instructionsPopup: nil
    )

    // MARK: - Modern Flow (v140)
    static let welcomeModern = PreviewModel(
        cardType: .basic,
        name: "welcomeModern",
        order: 10,
        title: "Say goodbye to creepy ads",
        body: "One choice protects you everywhere you go on the web. You can always change it later.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Set as Default Browser", action: OnboardingActions.openInstructionsPopup),
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

    static let customizationToolbarModern = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationToolbarModern",
        order: 20,
        title: "Choose where to put your address bar",
        body: "",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(
                title: "Bottom",
                action: OnboardingMultipleChoiceAction.toolbarBottom,
                imageID: "onboardingToolbarIconBottom"
            ),
            .init(
                title: "Top",
                action: OnboardingMultipleChoiceAction.toolbarTop,
                imageID: "onboardingToolbarIconTop"
            )
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationToolbar",
        imageID: "toolbar",
        instructionsPopup: nil
    )

    static let customizationThemeModern = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationThemeModern",
        order: 25,
        title: "Choose your theme",
        body: "",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(
                title: "System Default",
                action: OnboardingMultipleChoiceAction.themeSystemDefault,
                imageID: "onboardingThemeSystem"
            ),
            .init(
                title: "Light",
                action: OnboardingMultipleChoiceAction.themeLight,
                imageID: "onboardingThemeLight"
            ),
            .init(
                title: "Dark",
                action: OnboardingMultipleChoiceAction.themeDark,
                imageID: "onboardingThemeDark"
            )
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationTheme",
        imageID: "themeing",
        instructionsPopup: nil
    )

    static let signToSyncModern = PreviewModel(
        cardType: .basic,
        name: "signToSyncModern",
        order: 30,
        title: "Instantly pick up where you left off",
        body: "Get your bookmarks, history, and passwords on any device.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Start Syncing", action: OnboardingActions.syncSignIn),
            secondary: .init(title: "Not now", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_signToSync",
        imageID: "onboardingSyncWithIcons",
        instructionsPopup: nil
    )

    // MARK: - Japan Flow (v145)
    static let welcomeJapan = PreviewModel(
        cardType: .basic,
        name: "welcomeJapan",
        order: 10,
        title: "Say goodbye to creepy trackers",
        body: "One choice protects you everywhere you go on the web. You can always change it later.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Set as Default Browser", action: OnboardingActions.openInstructionsPopup),
            secondary: .init(title: "Not Now", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_welcome",
        imageID: "onboardingTrackersJapan",
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

    static let customizationToolbarJapan = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationToolbarJapan",
        order: 20,
        title: "Choose your address bar",
        body: "Start typing to get search suggestions, your top sites, bookmarks, " +
            "history and search engines — all in one place.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(
                title: "Bottom",
                action: OnboardingMultipleChoiceAction.toolbarBottom,
                imageID: "onboardingToolbarIconBottomJapan"
            ),
            .init(
                title: "Top",
                action: OnboardingMultipleChoiceAction.toolbarTop,
                imageID: "onboardingToolbarIconTopJapan"
            )
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationToolbar",
        imageID: "toolbar",
        instructionsPopup: nil
    )

    static let customizationThemeJapan = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationThemeJapan",
        order: 25,
        title: "Pick your theme",
        body: "Pick your favorite theme or have Firefox match your device, putting you in control.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(
                title: "Automatic",
                action: OnboardingMultipleChoiceAction.themeSystemDefault,
                imageID: "onboardingThemeSystemJapan"
            ),
            .init(
                title: "Light",
                action: OnboardingMultipleChoiceAction.themeLight,
                imageID: "onboardingThemeLightJapan"
            ),
            .init(
                title: "Dark",
                action: OnboardingMultipleChoiceAction.themeDark,
                imageID: "onboardingThemeDarkJapan"
            )
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationTheme",
        imageID: "themeing",
        instructionsPopup: nil
    )

    static let signToSyncJapan = PreviewModel(
        cardType: .basic,
        name: "signToSyncJapan",
        order: 30,
        title: "Instantly pick up where you left off",
        body: "Your bookmarks, passwords, and more are synced across your other devices. " +
            "Everything is protected with encryption, so only you can access it.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Start Syncing", action: OnboardingActions.syncSignIn),
            secondary: .init(title: "Not Now", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_signToSync",
        imageID: "onboardingSyncWithIconsJapan",
        instructionsPopup: nil
    )

    // MARK: - Legacy/Default (for backwards compatibility)
    static let welcome = welcomeBrandRefresh
    static let signToSync = signToSyncBrandRefresh
    static let customizationToolbar = customizationToolbarBrandRefresh

    // MARK: - Terms of Service
    static let tosBrandRefresh = PreviewModel(
        cardType: .basic,
        name: "tosBrandRefresh",
        order: 20,
        title: "Get ready to run free",
        body: "Speedy, safe, and won't sell you out. Browsing just got better.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.syncSignIn),
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

    static let tosModern = PreviewModel(
        cardType: .basic,
        name: "tosModern",
        order: 20,
        title: "Upgrade your browsing",
        body: "Load sites lightning fast\nAutomatic tracking protection\nSync on all your devices",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.syncSignIn),
            secondary: nil
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_termsOfUse",
        imageID: "fxHomeHeaderLogoBall",
        instructionsPopup: nil,
        embededLinkText: [
            EmbeddedLink(
                fullText: "By continuing, you agree to the %@",
                linkText: "Firefox Terms of Use",
                action: .openTermsOfService
            ),
            EmbeddedLink(
                fullText: "%@ cares about your privacy. Read more in our %@",
                linkText: "Privacy Notice",
                action: .openPrivacyNotice
            ),
            EmbeddedLink(
                fullText:
                    "To help improve the browser, %1$@ sends diagnostic and interaction data to %2$@. %3$@",
                linkText: "Manage",
                action: .openManageSettings
            )
        ]
    )

    // MARK: - Legacy/Default (for backwards compatibility)
    static let tos = tosBrandRefresh
}

extension PreviewModel {
    /// Brand Refresh flow preview cards (v148)
    static let brandRefreshFlow: [PreviewModel] = [
        .welcomeBrandRefresh,
        .customizationToolbarBrandRefresh,
        .customizationThemeBrandRefresh,
        .signToSyncBrandRefresh
    ]

    /// Modern flow preview cards (v140)
    static let modernFlow: [PreviewModel] = [
        .welcomeModern,
        .customizationToolbarModern,
        .customizationThemeModern,
        .signToSyncModern
    ]

    /// Japan flow preview cards (v145)
    static let japanFlow: [PreviewModel] = [
        .welcomeJapan,
        .customizationToolbarJapan,
        .customizationThemeJapan,
        .signToSyncJapan
    ]

    /// All of the built-in preview cards (defaults to Brand Refresh)
    static let all: [PreviewModel] = brandRefreshFlow
}

#Preview("Onboarding Flow - Brand Refresh") {
    OnboardingView<PreviewModel>(
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
        viewModel: OnboardingFlowViewModel(
            onboardingCards: PreviewModel.brandRefreshFlow,
            skipText: "Skip",
            variant: .brandRefresh,
            onActionTap: { _, _, _ in
            },
            onMultipleChoiceActionTap: { _, _ in },
            onComplete: { _, _ in }
        )
    )
}

#Preview("Onboarding Flow - Brand Refresh (Dark)") {
    OnboardingView<PreviewModel>(
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
        viewModel: OnboardingFlowViewModel(
            onboardingCards: PreviewModel.brandRefreshFlow,
            skipText: "Skip",
            variant: .brandRefresh,
            onActionTap: { _, _, _ in
            },
            onMultipleChoiceActionTap: { _, _ in },
            onComplete: { _, _ in }
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Onboarding Flow - Modern") {
    OnboardingView<PreviewModel>(
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
        viewModel: OnboardingFlowViewModel(
            onboardingCards: PreviewModel.modernFlow,
            skipText: "Skip",
            variant: .modern,
            onActionTap: { _, _, _ in
            },
            onMultipleChoiceActionTap: { _, _ in },
            onComplete: { _, _ in }
        )
    )
}

#Preview("Onboarding Flow - Japan") {
    OnboardingView<PreviewModel>(
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
        viewModel: OnboardingFlowViewModel(
            onboardingCards: PreviewModel.japanFlow,
            skipText: "Skip",
            variant: .japan,
            onActionTap: { _, _, _ in
            },
            onMultipleChoiceActionTap: { _, _ in },
            onComplete: { _, _ in }
        )
    )
}

#Preview("Terms of service") {
    TermsOfUseView(
        viewModel: TermsOfUseFlowViewModel(
            configuration: PreviewModel.tos,
            variant: .modern,
            onTermsOfUseTap: {},
            onPrivacyNoticeTap: {},
            onManageSettingsTap: {},
            onComplete: {}
        ),
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
    )
}

#Preview("Terms of service - Brand Refresh") {
    TermsOfUseView(
        viewModel: TermsOfUseFlowViewModel(
            configuration: PreviewModel.tos,
            variant: .brandRefresh,
            onTermsOfUseTap: {},
            onPrivacyNoticeTap: {},
            onManageSettingsTap: {},
            onComplete: {}
        ),
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
    )
}

#Preview("Terms of service - Brand Refresh (Dark)") {
    TermsOfUseView(
        viewModel: TermsOfUseFlowViewModel(
            configuration: PreviewModel.tos,
            variant: .brandRefresh,
            onTermsOfUseTap: {},
            onPrivacyNoticeTap: {},
            onManageSettingsTap: {},
            onComplete: {}
        ),
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
    )
    .preferredColorScheme(.dark)
}

#endif
