// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import OnboardingKit

struct OnboardingKitCardInfoModel: OnboardingCardInfoModelProtocol, UserFeaturePreferenceProvider {
    let cardType: OnboardingKit.OnboardingCardType
    let name: String
    let order: Int
    let title: String
    let body: String
    let instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?
    let link: OnboardingLinkInfoModel?
    let buttons: OnboardingButtons<OnboardingActions>
    let multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>]
    let onboardingType: OnboardingType
    let a11yIdRoot: String
    let imageID: String
    let embededLinkText: [EmbeddedLink]

    init(
        cardType: OnboardingKit.OnboardingCardType,
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
        self.embededLinkText = embededLinkText
    }

    var defaultSelectedButton: OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>? {
        guard !multipleChoiceButtons.isEmpty else { return nil }

        return findHighestPriorityButton() ?? multipleChoiceButtons.first
    }

    private func findHighestPriorityButton()
    -> OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>? {
        if multipleChoiceButtons.contains(where: { $0.action.isThemeAction }),
           let savedAction = savedThemeAction(),
           let matchedButton = multipleChoiceButtons.first(where: { $0.action == savedAction }) {
            return matchedButton
        }

        if multipleChoiceButtons.contains(where: { $0.action.isToolbarAction }),
           let savedAction = savedToolbarAction(),
           let matchedButton = multipleChoiceButtons.first(where: { $0.action == savedAction }) {
            return matchedButton
        }

        return nil
    }

    private func savedThemeAction() -> OnboardingMultipleChoiceAction? {
        let userDefault = UserDefaults.standard

        // System switch takes precedence
        if userDefault.bool(forKey: "prefKeySystemThemeSwitchOnOff") {
            return .themeSystemDefault
        }

        // Try the explicit saved theme
        guard let savedThemeDescription = userDefault.string(forKey: "prefKeyThemeName"),
              let savedTheme = ThemeType(rawValue: savedThemeDescription)
        else {
            return nil
        }

        switch savedTheme {
        case .dark:  return .themeDark
        case .light: return .themeLight
        default: return .themeSystemDefault
        }
    }

    private func savedToolbarAction() -> OnboardingMultipleChoiceAction? {
        switch userPreferences.searchBarPosition {
        case .top: return .toolbarTop
        case .bottom: return .toolbarBottom
        }
    }
}

// TODO: FXIOS-12866 Nimbus generated code should add `Sendable` to enums
extension OnboardingInstructionsPopupActions: @unchecked Sendable {}
extension OnboardingActions: @unchecked Sendable {}
extension OnboardingMultipleChoiceAction: @unchecked Sendable {}
extension OnboardingType: @unchecked Sendable {}

private extension OnboardingMultipleChoiceAction {
    var isThemeAction: Bool {
        switch self {
        case .themeDark, .themeLight, .themeSystemDefault:
            return true
        default:
            return false
        }
    }

    var isToolbarAction: Bool {
        switch self {
        case .toolbarTop, .toolbarBottom:
            return true
        default:
            return false
        }
    }
}
