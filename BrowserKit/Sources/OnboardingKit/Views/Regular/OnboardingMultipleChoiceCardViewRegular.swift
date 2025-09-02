// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingMultipleChoiceCardViewRegular<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    @State private var selectedAction: ViewModel.OnboardingMultipleChoiceActionType

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let viewModel: ViewModel
    let onBottomButtonAction: (ViewModel.OnboardingActionType, String) -> Void
    let onMultipleChoiceAction: (ViewModel.OnboardingMultipleChoiceActionType, String) -> Void

    init?(
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
        guard let defaultAction = viewModel.defaultSelectedButton?.action else {
            return nil
        }
        _selectedAction = State(initialValue: defaultAction)
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: UX.CardView.regularSizeSpacing) {
                    titleView
                        .padding(.top, UX.CardView.titleTopPadding)
                    OnboardingSegmentedControl<ViewModel.OnboardingMultipleChoiceActionType>(
                        selection: $selectedAction,
                        items: viewModel.multipleChoiceButtons,
                        windowUUID: windowUUID,
                        themeManager: themeManager
                    )
                    .onChange(of: selectedAction) { newAction in
                        onMultipleChoiceAction(newAction, viewModel.name)
                    }
                }
                .padding(UX.CardView.verticalPadding)
            }
            .scrollBounceBehavior(basedOnSize: true)
            primaryButton
                .padding(.bottom, UX.CardView.verticalPadding)
        }
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
            guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFont)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .fixedSize(horizontal: false, vertical: true)
            .alignmentGuide(.titleAlignment) { dimensions in dimensions[.bottom] }
    }

    var primaryButton: some View {
        Button(
            viewModel.buttons.primary.title,
            action: {
                onBottomButtonAction(
                    viewModel.buttons.primary.action,
                    viewModel.name
                )
            }
        )
        .font(UX.CardView.primaryActionFont)
        .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
        .buttonStyle(PrimaryButtonStyle(theme: themeManager.getCurrentTheme(for: windowUUID)))
        .frame(width: UX.CardView.primaryButtonWidthiPad)
    }

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        cardBackgroundColor = Color(color.layer2)
    }
}
