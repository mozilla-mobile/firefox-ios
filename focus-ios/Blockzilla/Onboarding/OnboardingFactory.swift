/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Onboarding
import SwiftUI

class TestOnboarding: OnboardingEventsHandling {
    @Published var route: Onboarding.ToolTipRoute?
    var routePublisher: Published<Onboarding.ToolTipRoute?>.Publisher { $route }
    func send(_ action: Onboarding.Action) {}
    func dismissTooltip(route: Onboarding.ToolTipRoute) {}
}

class OnboardingFactory {
    static func makeOnboardingEventsHandler(_ shouldShowNewOnboarding: () -> Bool) -> OnboardingEventsHandling {
        let getShownTips: () -> Set<ToolTipRoute> = {
            return UserDefaults
                .standard
                .data(forKey: OnboardingConstants.shownTips)
                .flatMap {
                    try? JSONDecoder().decode(Set<ToolTipRoute>.self, from: $0)
                } ?? []
        }

        let setShownTips: (Set<ToolTipRoute>) -> Void = { tips in
            let data = try? JSONEncoder().encode(tips)
            UserDefaults.standard.set(data, forKey: OnboardingConstants.shownTips)
        }

        if shouldShowNewOnboarding() {
            return OnboardingEventsHandlerV2(
                getShownTips: getShownTips,
                setShownTips: setShownTips
            )
        } else {
            return OnboardingEventsHandlerV1(
                getShownTips: getShownTips,
                setShownTips: setShownTips
            )
        }
    }

    static func make(onboardingType: OnboardingVersion, dismissAction: @escaping () -> Void, telemetry: @escaping (OnboardingTelemetryHelper.Event) -> Void) -> UIViewController {
        switch onboardingType {
        case .v2:
            let onboardingViewModel = OnboardingViewModel(
                config: .init(title: .onboardingTitle, subtitle: .onboardingSubtitleV2, buttonTitle: .onboardingButtonTitleV2),
                defaultBrowserConfig: .init(
                    title: .defaultBrowserOnboardingViewTitleV2,
                    firstSubtitle: .defaultBrowserOnboardingViewFirstSubtitleV2,
                    secondSubtitle: .defaultBrowserOnboardingViewSecondSubtitleV2,
                    topButtonTitle: .defaultBrowserOnboardingViewTopButtonTitleV2,
                    bottomButtonTitle: .defaultBrowserOnboardingViewBottomButtonTitleV2),
                tosConfig: .init(
                    title: .termsOfUseTitle,
                    subtitle: .termsOfUseSubtitle,
                    termsText: String(format: .termsOfUseText, String.termsLinkText),
                    privacyText: String(format: .privacyNoticeText, String.privacyLinkText),
                    termsLinkText: .termsLinkText,
                    privacyLinkText: .privacyLinkText,
                    buttonText: .termsOfUseButtonText,
                    doneButton: .doneButtonText,
                    errorMessage: .errorMessage,
                    retryButtonText: .retryButtonText
                ),
                isTosEnabled: true,
                termsURL: termsURL,
                privacyURL: privacyURL,
                dismissAction: dismissAction,
                telemetry: { action in
                    switch action {
                    case .getStartedAppeared:
                        telemetry(.getStartedAppeared)
                    case .getStartedCloseTapped:
                        telemetry(.getStartedCloseTapped)
                    case .getStartedButtonTapped:
                        telemetry(.getStartedButtonTapped)
                    case .defaultBrowserCloseTapped:
                        telemetry(.defaultBrowserCloseTapped)
                    case .defaultBrowserSettingsTapped:
                        telemetry(.defaultBrowserSettingsTapped)
                    case .defaultBrowserSkip:
                        telemetry(.defaultBrowserSkip)
                    case .defaultBrowserAppeared:
                        telemetry(.defaultBrowserAppeared)
                    // Add telemetry
                    case .onAcceptAndContinueTapped:
                        break
                    case .openTermsOfUse:
                        break
                    case .openPrivacyNotice:
                        break
                    }
                })
            let controller = PortraitHostingController(rootView: OnboardingView(viewModel: onboardingViewModel))
            controller.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .phone ? .overFullScreen : .formSheet
            controller.isModalInPresentation = true
            return controller

        case .v1:
            let controller = OnboardingViewController(
                config: .init(
                    onboardingTitle: .onboardingTitle,
                    onboardingSubtitle: .onboardingSubtitle,
                    instructions: [
                        .init(title: .onboardingIncognitoTitle, subtitle: .onboardingIncognitoDescription, image: .privateMode),
                        .init(title: .onboardingHistoryTitle, subtitle: .onboardingHistoryDescription, image: .history),
                        .init(title: .onboardingProtectionTitle, subtitle: .onboardingProtectionDescription, image: .settings)
                    ],
                    onboardingButtonTitle: .onboardingButtonTitle
                ),
                dismissOnboardingScreen: dismissAction
            )
            controller.modalPresentationStyle = .formSheet
            controller.isModalInPresentation = true
            return controller
        }
    }

    static var termsURL: URL {
        URL(string: "https://www.mozilla.org/about/legal/terms/firefox-focus/")!
    }

    static var privacyURL: URL {
        URL(string: "https://www.mozilla.org/privacy/firefox-focus/")!
    }
}

fileprivate extension String {
    static let onboardingTitle = String(format: .onboardingTitleFormat, AppInfo.config.productName)
    static let onboardingTitleFormat = NSLocalizedString("Onboarding.Title", value: "Welcome to Firefox %@!", comment: "Text for a label that indicates the title for onboarding screen. %@ is the app name (for example “Firefox Focus” or ”Firefox Klar”).")
    static let onboardingSubtitle = NSLocalizedString("Onboarding.Subtitle", value: "Take your private browsing to the next level.", comment: "Text for a label that indicates the subtitle for onboarding screen.")
    static let onboardingSubtitleV2 = NSLocalizedString("NewOnboarding.Subtitle.V2", value: "Fast. Private. No Distractions.", comment: "Text for a label that indicates the subtitle for the onboarding screen version 2.")
    static let onboardingIncognitoTitle = NSLocalizedString("Onboarding.Incognito.Title", value: "More than just incognito", comment: "Text for a label that indicates the title of incognito section from onboarding screen.")
    static let onboardingIncognitoDescription = String(format: NSLocalizedString("Onboarding.Incognito.Description", value: "%@ is a dedicated privacy browser with tracking protection and content blocking.", comment: "Text for a label that indicates the description of incognito section from onboarding screen. %@ is the app name (for example “Firefox Focus” or ”Firefox Klar”)."), AppInfo.productName)
    static let onboardingHistoryTitle = NSLocalizedString("Onboarding.History.Title", value: "Your history doesn’t follow you", comment: "Text for a label that indicates the title of history section from onboarding screen.")
    static let onboardingHistoryDescription = NSLocalizedString("Onboarding.History.Description", value: "Erase your browsing history, passwords, cookies, and prevent unwanted ads from following you in a simple click!", comment: "Text for a label that indicates the description of history section from onboarding screen.")
    static let onboardingProtectionTitle = NSLocalizedString("Onboarding.Protection.Title", value: "Protection at your own discretion", comment: "Text for a label that indicates the title of protection section from onboarding screen.")
    static let onboardingProtectionDescription = NSLocalizedString("Onboarding.Protection.Description", value: "Configure settings so you can decide how much or how little you share.", comment: "Text for a label that indicates the description of protection section from onboarding screen.")
    static let onboardingButtonTitle = NSLocalizedString("Onboarding.Button.Title", value: "Start browsing", comment: "Text for a label that indicates the title of button from onboarding screen")
    static let onboardingButtonTitleV2 = NSLocalizedString("NewOnboarding.Button.Title.V2", value: "Get Started", comment: "Text for a label that indicates the title of button from onboarding screen version 2.")

    static let defaultBrowserOnboardingViewTitleV2 = String(format: NSLocalizedString("Onboarding.DefaultBrowser.Title.V2", value: "%@ isn’t like other browsers", comment: "Text for a label that indicates the title for the default browser onboarding screen version 2. %@ is the app name (for example “Firefox Focus” or ”Firefox Klar”)."), AppInfo.shortProductName)
    static let defaultBrowserOnboardingViewFirstSubtitleV2 = NSLocalizedString("Onboarding.DefaultBrowser.FirstSubtitle.V2", value: "We clear your history when you close the app for extra privacy.", comment: "Text for a label that indicates the first subtitle for the default browser onboarding screen version 2.")
    static let defaultBrowserOnboardingViewSecondSubtitleV2 = String(format: NSLocalizedString("Onboarding.DefaultBrowser.SecondSubtitle.V2", value: "Make %@ your default to protect your data with every link you open.", comment: "Text for a label that indicates the second subtitle for the default browser onboarding screen version 2. %@ is the app name (for example “Firefox Focus” or ”Firefox Klar”)."), AppInfo.shortProductName)
    static let defaultBrowserOnboardingViewTopButtonTitleV2 = NSLocalizedString("Onboarding.DefaultBrowser.TopButtonTitle.V2", value: "Set as Default Browser", comment: "Text for a label that indicates the title of the top button from the default browser onboarding screen version 2.")
    static let defaultBrowserOnboardingViewBottomButtonTitleV2 = NSLocalizedString("Onboarding.DefaultBrowser.BottomButtonTitle.V2", value: "Skip", comment: "Text for a label that indicates the title of the bottom button from the default browser onboarding screen version 2.")
    static let termsOfUseTitle = String(
        format: NSLocalizedString(
            "Onboarding.TermsOfUse.Title",
            value: "Welcome to %@",
            comment: "Title for the Terms of Use screen during onboarding. %@ is the app name (for example “Firefox Focus” or ”Firefox Klar”)."
        ),
        AppInfo.productName
    )
    static let termsOfUseSubtitle = NSLocalizedString(
        "Onboarding.TermsOfUse.Subtitle",
        value: "Fast. Private. No distractions.",
        comment: "Subtitle for the Terms of Use screen during onboarding."
    )
    static let termsOfUseText = NSLocalizedString(
        "Onboarding.TermsOfUse.Text",
        value: "By continuing, you agree to %@.",
        comment: "Text that describes the agreement to the Firefox Terms of Use. %@ is a link using Onboarding.TermsOfUse.LinkText as text."
    )
    static let termsLinkText = NSLocalizedString(
        "Onboarding.TermsOfUse.LinkText",
        value: "Firefox Terms of Use",
        comment: "Used as a text for the link in Onboarding.TermsOfUse.Text."
    )
    static let privacyNoticeText = NSLocalizedString(
        "Onboarding.PrivacyNotice.Text",
        value: "Firefox cares about your privacy. Read more in %@.",
        comment: "Text that describes Firefox's commitment to privacy. %@ is a link using Onboarding.PrivacyNotice.LinkText as text."
    )
    static let privacyLinkText = NSLocalizedString(
        "Onboarding.PrivacyNotice.LinkText",
        value: "Privacy Notice",
        comment: "Used as a text for the link in Onboarding.PrivacyNotice.Text."
    )
    static let termsOfUseButtonText = NSLocalizedString(
        "Onboarding.TermsOfUse.ButtonText",
        value: "Agree and Continue",
        comment: "Label for the agreement button in the Terms of Use screen."
    )
    static let doneButtonText = NSLocalizedString(
        "Onboarding.TermsOfUse.Done.ButtonText",
        value: "Done",
        comment: "Button label to dismiss the Privacy Policy and Terms of Use screen."
    )
    
    static let errorMessage = NSLocalizedString(
        "Network.Offline.ErrorMessage",
        value: "The Internet connection appears to be offline.",
        comment: "Error message shown when no internet connection is available"
    )

    static let retryButtonText = NSLocalizedString(
        "Network.Offline.RetryButton",
        value: "Try Again",
        comment: "Button text for retrying network connection"
    )
}
