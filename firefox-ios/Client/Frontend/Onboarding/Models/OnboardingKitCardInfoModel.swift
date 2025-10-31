// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import OnboardingKit
import Shared

struct OnboardingKitCardInfoModel: OnboardingKit.OnboardingCardInfoModelProtocol {
    // MARK: Protocol properties
    let cardType: OnboardingKit.OnboardingCardType
    let name: String
    let order: Int
    let title: String
    let body: String
    let instructionsPopup: OnboardingKit.OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?
    let link: OnboardingKit.OnboardingLinkInfoModel?
    let buttons: OnboardingKit.OnboardingButtons<OnboardingActions>
    let multipleChoiceButtons: [OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>]
    let onboardingType: OnboardingType
    let a11yIdRoot: String
    let imageID: String
    let embededLinkText: [OnboardingKit.EmbeddedLink]

    // MARK: Current state properties (for relaunched onboarding)
    /// Current toolbar position, if available (nil means fresh install).
    /// Note: SearchBarPosition is defined in Client module and is Sendable-compatible
    let currentToolbarPosition: SearchBarPosition?
    /// Current theme action, if available (nil means fresh install)
    let currentThemeAction: OnboardingMultipleChoiceAction?

    // Required initializer (matches protocol exactly)
    init(
        cardType: OnboardingKit.OnboardingCardType,
        name: String,
        order: Int,
        title: String,
        body: String,
        link: OnboardingKit.OnboardingLinkInfoModel?,
        buttons: OnboardingKit.OnboardingButtons<OnboardingActions>,
        multipleChoiceButtons: [OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>],
        onboardingType: OnboardingType,
        a11yIdRoot: String,
        imageID: String,
        instructionsPopup: OnboardingKit.OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?,
        embededLinkText: [OnboardingKit.EmbeddedLink]
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
        self.currentToolbarPosition = nil
        self.currentThemeAction = nil
    }

    // Convenience initializer with current state (for relaunched onboarding)
    init(
        cardType: OnboardingKit.OnboardingCardType,
        name: String,
        order: Int,
        title: String,
        body: String,
        link: OnboardingKit.OnboardingLinkInfoModel?,
        buttons: OnboardingKit.OnboardingButtons<OnboardingActions>,
        multipleChoiceButtons: [OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>],
        onboardingType: OnboardingType,
        a11yIdRoot: String,
        imageID: String,
        instructionsPopup: OnboardingKit.OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?,
        embededLinkText: [OnboardingKit.EmbeddedLink],
        currentToolbarPosition: SearchBarPosition?,
        currentThemeAction: OnboardingMultipleChoiceAction?
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
        self.currentToolbarPosition = currentToolbarPosition
        self.currentThemeAction = currentThemeAction
    }

    var defaultSelectedButton: OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>? {
        guard !multipleChoiceButtons.isEmpty else { return nil }

        // First, try to match current state for relaunched onboarding
        if let matchedButton = findButtonMatchingCurrentState() {
            return matchedButton
        }

        // Otherwise, use default priority (for fresh installs)
        return findHighestPriorityButton() ?? multipleChoiceButtons.first
    }

    /// Finds a button that matches the current system state (for relaunched onboarding)
    private func findButtonMatchingCurrentState()
    -> OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>? {
        // Check for toolbar position match
        if let currentPosition = currentToolbarPosition {
            let matchingAction: OnboardingMultipleChoiceAction =
                currentPosition == .bottom ? .toolbarBottom : .toolbarTop
            if let matchingButton = multipleChoiceButtons.first(where: { $0.action == matchingAction }) {
                return matchingButton
            }
        }

        // Check for theme match
        if let currentTheme = currentThemeAction {
            if let matchingButton = multipleChoiceButtons.first(where: { $0.action == currentTheme }) {
                return matchingButton
            }
        }

        return nil
    }

    private func findHighestPriorityButton()
    -> OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>? {
        let selectableButtons = multipleChoiceButtons
            .filter { hasDefaultSelection($0.action) }
            .map { ($0, defaultSelectionPriority($0.action)) }

        return selectableButtons
            .min(by: { $0.1 < $1.1 })?
            .0 // Return the button, not the priority
    }

    private func hasDefaultSelection(_ action: OnboardingMultipleChoiceAction) -> Bool {
        switch action {
        case .toolbarBottom, .toolbarTop, .themeSystemDefault:
            return true
        default:
            return false
        }
    }

    private func defaultSelectionPriority(_ action: OnboardingMultipleChoiceAction) -> Int {
        switch action {
        case .toolbarBottom: return 1  // Highest priority for toolbar
        case .toolbarTop: return 2     // Lower priority for toolbar
        case .themeSystemDefault: return 1  // Highest priority for theme (automatic)
        case .themeLight: return 2     // Lower priority for theme
        case .themeDark: return 3      // Lower priority for theme
        // swiftlint:disable:next unavailable_enum_case
        @unknown default: return Int.max        // No priority (future-proofing)
        }
    }
}

// TODO: FXIOS-12866 Nimbus generated code should add `Sendable` to enums
extension OnboardingInstructionsPopupActions: @unchecked Sendable {}
extension OnboardingActions: @unchecked Sendable {}
extension OnboardingMultipleChoiceAction: @unchecked Sendable {}
extension OnboardingType: @unchecked Sendable {}
