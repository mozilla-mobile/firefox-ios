// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct OnboardingCardView<VM: OnboardingCardInfoModelProtocol>: View {
    public let viewModel: VM
    public let onPrimary: () -> Void
    public let onSecondary: () -> Void
    public let onLink: () -> Void
//    public let onChoice: (OnboardingMultipleChoiceButtonModel) -> Void

    @Environment(\.theme) private var theme

    public init(
        viewModel: VM,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void,
        onLink: @escaping () -> Void// ,
//        onChoice: @escaping (OnboardingMultipleChoiceButtonModel) -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
        self.onLink = onLink
//        self.onChoice = onChoice
    }

    public var body: some View {
        Group {
            switch viewModel.cardType {
            case .basic:
                OnboardingBasicCardView(
                    viewModel: viewModel,
                    onPrimary: onPrimary,
                    onSecondary: onSecondary,
                    onLink: onLink
                )
            case .multipleChoice:
                OnboardingMultipleChoiceCardView(
                    viewModel: viewModel,
                    onPrimary: onPrimary,
                    onSecondary: onSecondary// ,
//                    onChoice: onChoice
                )
            }
        }
        .theme(theme)
    }
}
