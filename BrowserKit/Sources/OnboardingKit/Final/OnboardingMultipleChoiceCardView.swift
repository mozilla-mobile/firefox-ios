// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct OnboardingMultipleChoiceCardView<VM: OnboardingCardInfoModelProtocol>: View {
    public let viewModel: VM
    public let onPrimary: () -> Void
    public let onSecondary: () -> Void
//    public let onChoice: (OnboardingMultipleChoiceButtonModel) -> Void

    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var selectedAction: VM.OnboardingMultipleChoiceActionType

    public init(
        viewModel: VM,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void,
//        onChoice: @escaping (OnboardingMultipleChoiceButtonModel) -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
//        self.onChoice = onChoice
        self._selectedAction = State(initialValue: viewModel.multipleChoiceButtons.first!.action)
    }

    private var imageHeight: CGFloat {
        let coef: CGFloat = UIDevice.isTiny
            ? 1.0
            : (UIDevice.isSmall ? 0.85 : 1.0)
        return 200 * coef
    }

    private var topPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? 70 : 90
        } else if UIDevice.isSmall {
            return 40
        } else {
            return UIScreen.main.bounds.height * 0.1
        }
    }

    private var bottomPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? -32 : 0
        }
        return 0
    }

    private var horizontalPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? 100 : 24
        }
        return 24
    }

    public var body: some View {
        ScrollView {
            VStack {

                Spacer()

                Text(viewModel.title)
                    .font(UIDevice.isSmall ? .title3 : .title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
                    .accessibility(addTraits: .isHeader)

                Spacer()

                OnboardingSegmentedControl<VM.OnboardingMultipleChoiceActionType>(
                    selection: $selectedAction,
                    items: viewModel.multipleChoiceButtons
                )

                Spacer()

                Button(viewModel.buttons.primary.title) {
                    // primary action
                }
                .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
                .buttonStyle(PrimaryButtonStyle())
            }
            .frame(height: 600)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1),
                            radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 24)
        }
    }
}
