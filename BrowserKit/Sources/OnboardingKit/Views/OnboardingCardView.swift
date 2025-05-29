// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

public struct OnboardingCardView<VM: OnboardingCardInfoModelProtocol>: View {
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    public let viewModel: VM
    public let onBottomButtonAction: (VM.OnboardingActionType, String) -> Void
    public let onMultipleChoiceAction: (VM.OnboardingMultipleChoiceActionType, String) -> Void
    public let onLinkTap: (String) -> Void

    public init(
        viewModel: VM,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onBottomButtonAction: @escaping (VM.OnboardingActionType, String) -> Void,
        onMultipleChoiceAction: @escaping (VM.OnboardingMultipleChoiceActionType, String) -> Void,
        onLinkTap: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onBottomButtonAction = onBottomButtonAction
        self.onMultipleChoiceAction = onMultipleChoiceAction
        self.onLinkTap = onLinkTap
    }

    public var body: some View {
        Group {
            switch viewModel.cardType {
            case .basic:
                OnboardingBasicCardView(
                    viewModel: viewModel,
                    windowUUID: windowUUID,
                    themeManager: themeManager,
                    onBottomButtonAction: onBottomButtonAction,
                    onLinkTap: onLinkTap
                )
            case .multipleChoice:
                OnboardingMultipleChoiceCardView(
                    viewModel: viewModel,
                    windowUUID: windowUUID,
                    themeManager: themeManager,
                    onBottomButtonAction: onBottomButtonAction,
                    onMultipleChoiceAction: onMultipleChoiceAction,
                    onLinkTap: onLinkTap
                )
            }
        }
    }
}
