// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import OnboardingKit

extension OnboardingKit.OnboardingCardInfoModelProtocol
where OnboardingMultipleChoiceActionType == OnboardingMultipleChoiceAction {
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
            .filter { $0.action.hasDefaultSelection }
            .map { ($0, $0.action.defaultSelectionPriority) }

        return selectableButtons
            .min(by: { $0.1 < $1.1 })?
            .0 // Return the button, not the priority
    }
}
