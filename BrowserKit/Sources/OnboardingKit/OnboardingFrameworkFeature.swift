//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//
//import Foundation
//import SwiftUI
//
//// MARK: - Model Types
//
///// Typealias for arbitrary condition names (JEXL expressions).
//public typealias ConditionName = String
//
///// Top-level feature config
//public struct OnboardingFrameworkFeature {
//    public var conditions: [ConditionName: String]
//    public var cards: [String: NimbusOnboardingCardData]
//    public var dismissable: Bool
//}
//
///// Describes one onboarding card
//public struct NimbusOnboardingCardData: Identifiable {
//    public let id = UUID()
//    public var cardType: OnboardingCardType
//    public var order: Int
//    public var title: String
//    public var body: String
//    public var image: NimbusOnboardingHeaderImage
//    public var link: NimbusOnboardingLink?
//    public var buttons: NimbusOnboardingButtons
//    public var multipleChoiceButtons: [NimbusOnboardingMultipleChoiceButton]
//    public var instructionsPopup: NimbusOnboardingInstructionPopup?
//    public var prerequisites: [ConditionName]
//    public var disqualifiers: [ConditionName]
//    public var onboardingType: OnboardingType
//}
//
///// A link shown on a card
//public struct NimbusOnboardingLink {
//    public var title: String
//    public var url: URL
//}
//
///// One button (primary or secondary)
//public struct NimbusOnboardingButton {
//    public var title: String
//    public var action: OnboardingActions
//}
//
///// Group of up to two buttons
//public struct NimbusOnboardingButtons {
//    public var primary: NimbusOnboardingButton
//    public var secondary: NimbusOnboardingButton?
//}
//
///// One choice in a multiple-choice card
//public struct NimbusOnboardingMultipleChoiceButton {
//    public var title: String
//    public var image: NimbusOnboardingMultipleChoiceButtonImage
//    public var action: OnboardingMultipleChoiceAction
//}
//
///// The “...” popup instruction card
//public struct NimbusOnboardingInstructionPopup {
//    public var title: String
//    public var instructions: [String]
//    public var buttonTitle: String
//    public var buttonAction: OnboardingInstructionsPopupActions
//}
//
//// MARK: - Enums
//
//public enum OnboardingActions: String, Codable {
//    case forwardOneCard       = "forward-one-card"
//    case forwardTwoCard       = "forward-two-card"
//    case forwardThreeCard     = "forward-three-card"
//    case syncSignIn           = "sync-sign-in"
//    case requestNotifications = "request-notifications"
//    case setDefaultBrowser    = "set-default-browser"
//    case openInstructions     = "open-instructions-popup"
//    case readPrivacyPolicy    = "read-privacy-policy"
//    case openIOSSettings      = "open-ios-fx-settings"
//    case endOnboarding        = "end-onboarding"
//}
//
//public enum OnboardingInstructionsPopupActions: String, Codable {
//    case openIOSSettings     = "open-ios-fx-settings"
//    case dismissAndNext      = "dismiss-and-next-card"
//    case dismiss             = "dismiss"
//}
//
//public enum NimbusOnboardingHeaderImage: String, Codable {
//    case welcomeCTD        = "welcome-ctd"
//    case notificationsCTD  = "notifications-ctd"
//    case syncDevicesCTD    = "sync-devices-ctd"
//    case notifications     = "notifications"
//    case syncDevices       = "sync-devices"
//    case setDefaultSteps   = "set-default-steps"
//    case setToDock         = "set-to-dock"
//    case searchWidget      = "search-widget"
//    case welcomeGlobe      = "welcome-globe"
//    case themeing          = "themeing"
//    case toolbar           = "toolbar"
//    case customizeFirefox  = "customize-firefox"
//}
//
//public enum OnboardingCardType: String, Codable {
//    case basic
//    case multipleChoice = "multiple-choice"
//}
//
//public enum OnboardingType: String, Codable {
//    case freshInstall = "fresh-install"
//    case upgrade
//}
//
//public enum OnboardingMultipleChoiceAction: String, Codable {
//    case themeSystemDefault = "theme-system-default"
//    case themeDark          = "theme-dark"
//    case themeLight         = "theme-light"
//    case toolbarTop         = "toolbar-top"
//    case toolbarBottom      = "toolbar-bottom"
//}
//
//public enum NimbusOnboardingMultipleChoiceButtonImage: String, Codable {
//    case themeSystem  = "theme-system"
//    case themeDark    = "theme-dark"
//    case themeLight   = "theme-light"
//    case toolbarTop   = "toolbar-top"
//    case toolbarBottom = "toolbar-bottom"
//}
//
//// MARK: –– Dummy Data for All Cards
//
//extension NimbusOnboardingCardData {
//    static let welcome = NimbusOnboardingCardData(
//        cardType: .basic,
//        order: 10,
//        title: "Welcome to Firefox",
//        body: "Get started with your new browser.",
//        image: .welcomeGlobe,
//        link: nil,
//        buttons: .init(
//            primary: .init(title: "Get Started", action: .forwardOneCard),
//            secondary: .init(title: "Skip", action: .forwardOneCard)
//        ),
//        multipleChoiceButtons: [],
//        instructionsPopup: .init(
//            title: "Set as Default Browser",
//            instructions: [
//                "Open Settings",
//                "Find Default Apps",
//                "Select Firefox"
//            ],
//            buttonTitle: "Open Settings",
//            buttonAction: .openIOSSettings
//        ),
//        prerequisites: ["ALWAYS"],
//        disqualifiers: [],
//        onboardingType: .freshInstall
//    )
//
//    static let signToSync = NimbusOnboardingCardData(
//        cardType: .basic,
//        order: 20,
//        title: "Sign in to Sync",
//        body: "Keep your data in sync across devices.",
//        image: .syncDevices,
//        link: nil,
//        buttons: .init(
//            primary: .init(title: "Sign In", action: .syncSignIn),
//            secondary: .init(title: "Skip", action: .forwardOneCard)
//        ),
//        multipleChoiceButtons: [],
//        instructionsPopup: nil,
//        prerequisites: ["ALWAYS"],
//        disqualifiers: [],
//        onboardingType: .freshInstall
//    )
//
//    static let notificationPermissions = NimbusOnboardingCardData(
//        cardType: .basic,
//        order: 30,
//        title: "Enable Notifications",
//        body: "Stay up to date with alerts.",
//        image: .notifications,
//        link: nil,
//        buttons: .init(
//            primary: .init(title: "Turn On", action: .requestNotifications),
//            secondary: .init(title: "Skip", action: .forwardOneCard)
//        ),
//        multipleChoiceButtons: [],
//        instructionsPopup: nil,
//        prerequisites: ["ALWAYS"],
//        disqualifiers: [],
//        onboardingType: .freshInstall
//    )
//
//    static let customizationTheme = NimbusOnboardingCardData(
//        cardType: .multipleChoice,
//        order: 40,
//        title: "Pick a Theme",
//        body: "Choose light, dark, or system default.",
//        image: .themeing,
//        link: nil,
//        buttons: .init(
//            primary: .init(title: "Continue", action: .forwardOneCard),
//            secondary: nil
//        ),
//        multipleChoiceButtons: [
//            .init(title: "System Default", image: .themeSystem, action: .themeSystemDefault),
//            .init(title: "Light",          image: .themeLight,  action: .themeLight),
//            .init(title: "Dark",           image: .themeDark,   action: .themeDark),
//        ],
//        instructionsPopup: nil,
//        prerequisites: ["ALWAYS"],
//        disqualifiers: [],
//        onboardingType: .freshInstall
//    )
//
//    static let customizationToolbar = NimbusOnboardingCardData(
//        cardType: .multipleChoice,
//        order: 41,
//        title: "Toolbar Position",
//        body: "Where should the toolbar appear?",
//        image: .toolbar,
//        link: nil,
//        buttons: .init(
//            primary: .init(title: "Continue", action: .forwardOneCard),
//            secondary: nil
//        ),
//        multipleChoiceButtons: [
//            .init(title: "Top",    image: .toolbarTop,    action: .toolbarTop),
//            .init(title: "Bottom", image: .toolbarBottom, action: .toolbarBottom),
//        ],
//        instructionsPopup: nil,
//        prerequisites: ["ALWAYS"],
//        disqualifiers: [],
//        onboardingType: .freshInstall
//    )
//
//    static let updateWelcome = NimbusOnboardingCardData(
//        cardType: .basic,
//        order: 10,
//        title: "Welcome Back",
//        body: "Here's what's new in this update.",
//        image: .welcomeGlobe,
//        link: nil,
//        buttons: .init(
//            primary: .init(title: "Next", action: .forwardOneCard),
//            secondary: nil
//        ),
//        multipleChoiceButtons: [],
//        instructionsPopup: nil,
//        prerequisites: ["NEVER"],
//        disqualifiers: [],
//        onboardingType: .upgrade
//    )
//
//    static let updateSignToSync = NimbusOnboardingCardData(
//        cardType: .basic,
//        order: 20,
//        title: "Reconnect Sync",
//        body: "Sign in again to keep syncing.",
//        image: .syncDevices,
//        link: nil,
//        buttons: .init(
//            primary: .init(title: "Sign In", action: .syncSignIn),
//            secondary: .init(title: "Later", action: .forwardOneCard)
//        ),
//        multipleChoiceButtons: [],
//        instructionsPopup: nil,
//        prerequisites: ["NEVER"],
//        disqualifiers: [],
//        onboardingType: .upgrade
//    )
//}
//
//extension OnboardingFrameworkFeature {
//    static let previewAll = OnboardingFrameworkFeature(
//        conditions: [
//            "ALWAYS": "true",
//            "NEVER":  "false"
//        ],
//        cards: [
//            "welcome": .welcome,
//            "sign-to-sync": .signToSync,
//            "notification-permissions": .notificationPermissions,
//            "customization-theme": .customizationTheme,
//            "customization-toolbar": .customizationToolbar,
//            "update-welcome": .updateWelcome,
//            "update-sign-to-sync": .updateSignToSync
//        ],
//        dismissable: true
//    )
//}
