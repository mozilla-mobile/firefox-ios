// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct OnboardingCardViewRegular<ViewModel: OnboardingCardInfoModelProtocol>: View {
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let viewModel: ViewModel
    let onBottomButtonAction: (ViewModel.OnboardingActionType, String) -> Void
    let onMultipleChoiceAction: (ViewModel.OnboardingMultipleChoiceActionType, String) -> Void

    init(
        viewModel: ViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onBottomButtonAction: @escaping (ViewModel.OnboardingActionType, String) -> Void,
        onMultipleChoiceAction: @escaping (ViewModel.OnboardingMultipleChoiceActionType, String) -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onBottomButtonAction = onBottomButtonAction
        self.onMultipleChoiceAction = onMultipleChoiceAction
    }

    var body: some View {
        Group {
            switch viewModel.cardType {
            case .basic:
                OnboardingBasicCardViewRegular(
                    viewModel: viewModel,
                    windowUUID: windowUUID,
                    themeManager: themeManager,
                    onBottomButtonAction: onBottomButtonAction
                )
            case .multipleChoice:
                OnboardingMultipleChoiceCardViewRegular(
                    viewModel: viewModel,
                    windowUUID: windowUUID,
                    themeManager: themeManager,
                    onBottomButtonAction: onBottomButtonAction,
                    onMultipleChoiceAction: onMultipleChoiceAction
                )
            }
        }
    }
}
