// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#if DEBUG
import SwiftUI

private struct PreviewModel: OnboardingCardInfoModelProtocol {
    var image: UIImage? {
        UIImage(
            named: imageID,
            in: Bundle.module,
            compatibleWith: nil
        )
    }
    
    // MARK: Protocol properties
    var cardType: OnboardingCardType
    var name: String
    var order: Int
    var title: String
    var body: String
    var instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?
    var link: OnboardingLinkInfoModel?
    var buttons: OnboardingButtons<OnboardingActions>
    var multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>]
    var onboardingType: OnboardingType
    var a11yIdRoot: String
    var imageID: String

    // Required initializer
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
        instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>? = nil
    ) {
        self.cardType = cardType
        self.name = name
        self.order = order
        self.title = title
        self.body = body
        self.link = link
        self.buttons = buttons
        self.multipleChoiceButtons = multipleChoiceButtons
        self.onboardingType = onboardingType
        self.a11yIdRoot = a11yIdRoot
        self.imageID = imageID
        self.instructionsPopup = instructionsPopup
    }
}

public enum OnboardingType: String, Codable {
    case freshInstall = "fresh-install"
    case upgrade
}

public enum OnboardingMultipleChoiceAction: String, CaseIterable, Codable {
    
    /// Will will set the theme to dark mode
    ///
    case themeDark = "theme-dark"
    
    /// Will set the theme to light mode
    ///
    case themeLight = "theme-light"
    
    /// Will set the theme to use the system theme
    ///
    case themeSystemDefault = "theme-system-default"
    
    /// Will set the toolbar on the bottom
    ///
    case toolbarBottom = "toolbar-bottom"
    
    /// Will set the toolbar on the top
    ///
    case toolbarTop = "toolbar-top"
}

extension OnboardingMultipleChoiceAction {
    public var id: String { rawValue }
    
    public var displayName: String {
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

public enum OnboardingInstructionsPopupActions: String, CaseIterable, Codable {
    case dismiss = "dismiss"
    case dismissAndNextCard = "dismiss-and-next-card"
    case openIosFxSettings = "open-ios-fx-settings"
}

extension OnboardingInstructionsPopupActions {
    public var displayName: String {
        return self.rawValue
    }
    
    public var id: String {
        return self.rawValue
    }
}

public enum OnboardingActions: String, CaseIterable, Codable {
    
    /// Will end the onboarding on a set card
    ///
    case endOnboarding = "end-onboarding"
    
    /// Will take the user to the next card
    ///
    case forwardOneCard = "forward-one-card"
    
    /// Will take the user to the next card
    ///
    case forwardThreeCard = "forward-three-card"
    
    /// Will take the user to the next card
    ///
    case forwardTwoCard = "forward-two-card"
    
    /// Will open up a popup with instructions for something
    ///
    case openInstructionsPopup = "open-instructions-popup"
    
    /// Will take the user to the default browser settings in the iOS system
    /// settings
    ///
    case openIosFxSettings = "open-ios-fx-settings"
    
    /// Will open a webview where the user can read the privacy policy
    ///
    case readPrivacyPolicy = "read-privacy-policy"
    
    /// Will request to allow notifications from the user
    ///
    case requestNotifications = "request-notifications"
    
    /// Will send the user to settings to set Firefox as their default browser and
    /// advance to next card
    ///
    case setDefaultBrowser = "set-default-browser"
    
    /// Will take the user to the sync sign in flow
    ///
    case syncSignIn = "sync-sign-in"
}

extension OnboardingActions {
    public var displayName: String {
        return self.rawValue
    }
    
    public var id: String {
        return self.rawValue
    }
}

extension PreviewModel {
    static let welcome = PreviewModel(
        cardType: .basic,
        name: "welcome",
        order: 10,
        title: "Get automatic protection from trackers",
        body: "One tap helps stop companies spying on your clicks.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Get Started", action: OnboardingActions.forwardOneCard),
            secondary: .init(title: "Not Now", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_welcome",
        imageID: "trackers",
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
        title: "Sync everywhere you use Firefox",
        body: "Get bookmarks, tabs, and passwords on any device. All protected with encryption.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Sign In", action: OnboardingActions.syncSignIn),
            secondary: .init(title: "Skip", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_signToSync",
        imageID: "syncWithIcons",
        instructionsPopup: nil
    )

    static let notificationPermissions = PreviewModel(
        cardType: .basic,
        name: "notificationPermissions",
        order: 30,
        title: "Enable Notifications",
        body: "Stay up to date with alerts.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Turn On", action: OnboardingActions.requestNotifications),
            secondary: .init(title: "Skip", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_notificationPermissions",
        imageID: "notifications",
        instructionsPopup: nil
    )

    static let customizationTheme = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationTheme",
        order: 40,
        title: "Pick a Theme",
        body: "Choose light, dark, or system default.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(title: "System Default", action: OnboardingMultipleChoiceAction.themeSystemDefault, imageID: "themeSystem"),
            .init(title: "Light",          action: OnboardingMultipleChoiceAction.themeLight,         imageID: "themeLight"),
            .init(title: "Dark",           action: OnboardingMultipleChoiceAction.themeDark,          imageID: "themeDark"),
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationTheme",
        imageID: "themeing",
        instructionsPopup: nil
    )

    static let customizationToolbar = PreviewModel(
        cardType: .multipleChoice,
        name: "customizationToolbar",
        order: 41,
        title: "Toolbar Position",
        body: "Where should the toolbar appear?",
        link: nil,
        buttons: .init(
            primary: .init(title: "Continue", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [
            .init(title: "Top",    action: OnboardingMultipleChoiceAction.toolbarTop,    imageID: "toolbarTop"),
            .init(title: "Bottom", action: OnboardingMultipleChoiceAction.toolbarBottom, imageID: "toolbarBottom"),
        ],
        onboardingType: .freshInstall,
        a11yIdRoot: "onboarding_customizationToolbar",
        imageID: "toolbar",
        instructionsPopup: nil
    )

    static let updateWelcome = PreviewModel(
        cardType: .basic,
        name: "updateWelcome",
        order: 10,
        title: "Welcome Back",
        body: "Here's what's new in this update.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Next", action: OnboardingActions.forwardOneCard),
            secondary: nil
        ),
        multipleChoiceButtons: [],
        onboardingType: .upgrade,
        a11yIdRoot: "onboarding_updateWelcome",
        imageID: "welcomeGlobe",
        instructionsPopup: nil
    )

    static let updateSignToSync = PreviewModel(
        cardType: .basic,
        name: "updateSignToSync",
        order: 20,
        title: "Reconnect Sync",
        body: "Sign in again to keep syncing.",
        link: nil,
        buttons: .init(
            primary: .init(title: "Sign In", action: OnboardingActions.syncSignIn),
            secondary: .init(title: "Later", action: OnboardingActions.forwardOneCard)
        ),
        multipleChoiceButtons: [],
        onboardingType: .upgrade,
        a11yIdRoot: "onboarding_updateSignToSync",
        imageID: "syncDevices",
        instructionsPopup: nil
    )
}

extension PreviewModel {
    /// All of the built-in preview cards
    static let all: [PreviewModel] = [
        .welcome,
//        .notificationPermissions,
//        .customizationTheme,
        .customizationToolbar,
        .signToSync,
//        .updateWelcome,
//        .updateSignToSync
    ]
}

// 1. Fix the generics by making concrete aliases:
private typealias BasicCard       = OnboardingBasicCardView<PreviewModel>
private typealias MultipleChoice  = OnboardingMultipleChoiceCardView<PreviewModel>
private typealias Card  = OnboardingCardView<PreviewModel>

// 2. Your PreviewProvider:
struct OnboardingUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Card(
                viewModel: PreviewModel.welcome,
                onPrimary:   { print("Next tapped") },
                onSecondary: { print("Skip tapped") },
                onLink:      { print("Learn more tapped") }//,
//                onChoice:    { choice in print("Chose \(choice.title)") }
            )
            .previewDisplayName("Basic – iPhone 12")
            .previewDevice("iPhone 12")

            Card(
                viewModel: PreviewModel.customizationTheme,
                onPrimary:   { print("Done tapped") },
                onSecondary: { /* no secondary here */ },
                onLink:      { print("Learn more tapped") }//,
//                onChoice:    { choice in print("Chose \(choice.title)") }
            )
            .previewDisplayName("Multiple Choice – SE1")
            .previewDevice("iPhone SE (1st generation)")
        }
    }
}

struct OnboardingView<VM: OnboardingCardInfoModelProtocol>: View {
    var onComplete: () -> Void

    let onboardingCards: [VM]

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            MilkyWayMetalView()
                .edgesIgnoringSafeArea(.all)
            TabView(selection: $currentPage) {
                ForEach(onboardingCards, id: \.name)  { card in
                    VStack {
                        OnboardingCardView(
                            viewModel: card,
                            onPrimary:   { print("Done tapped") },
                            onSecondary: { /* no secondary here */ },
                            onLink:      { print("Learn more tapped") }//,
//                            onChoice:    { choice in print("Chose \(choice.title)") }
                        )
                    }
                    .tag(card.name)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

#Preview {
    OnboardingView<PreviewModel>(
        onComplete: {
        },
        onboardingCards: PreviewModel.all)
}

#endif
