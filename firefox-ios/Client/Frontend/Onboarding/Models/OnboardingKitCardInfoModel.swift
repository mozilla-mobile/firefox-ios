// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import OnboardingKit

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

    // Required initializer
    init(
        cardType: OnboardingKit.OnboardingCardType,
        name: String,
        order: Int,
        title: String,
        body: String,
        link: OnboardingKit.OnboardingLinkInfoModel? = nil,
        buttons: OnboardingKit.OnboardingButtons<OnboardingActions>,
        multipleChoiceButtons: [OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>] = [],
        onboardingType: OnboardingType = .freshInstall,
        a11yIdRoot: String,
        imageID: String,
        instructionsPopup: OnboardingKit.OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>? = nil,
        embededLinkText: [OnboardingKit.EmbeddedLink] = []
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

    var defaultSelectedButton: OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>? {
        guard !multipleChoiceButtons.isEmpty else { return nil }

        let toolbarLayout = FxNimbus.shared.features
            .toolbarRefactorFeature
            .value()
            .layout

        let isVersionedLayout = [.version1, .version2, .baseline].contains(toolbarLayout)

        if isVersionedLayout {
            return findHighestPriorityButton() ?? multipleChoiceButtons.first
        }

        return multipleChoiceButtons.first
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
        case .toolbarBottom, .toolbarTop:
            return true
        default:
            return false
        }
    }

    private func defaultSelectionPriority(_ action: OnboardingMultipleChoiceAction) -> Int {
        switch action {
        case .toolbarBottom: return 1  // Highest priority
        case .toolbarTop: return 2     // Lower priority
        default: return Int.max        // No priority
        }
    }

    var image: UIImage? {
        return UIImage(named: imageID)
    }
}

// TODO: FXIOS-12866 Nimbus generated code should add `Sendable` to enums
extension OnboardingInstructionsPopupActions: @unchecked Sendable {}
extension OnboardingActions: @unchecked Sendable {}
extension OnboardingMultipleChoiceAction: @unchecked Sendable {}
extension OnboardingType: @unchecked Sendable {}
