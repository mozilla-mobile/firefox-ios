// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingMultipleChoiceCardViewRegular<ViewModel: OnboardingCardInfoModelProtocol>: ThemeableView {
    @State var theme: Theme
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
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
        guard let defaultAction = viewModel.defaultSelectedButton?.action else {
            return nil
        }
        _selectedAction = State(initialValue: defaultAction)
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: UX.CardView.regularSizeSpacing) {
                    titleView
                        .padding(.top, UX.CardView.titleTopPadding)
                    OnboardingSegmentedControl<ViewModel.OnboardingMultipleChoiceActionType>(
                        theme: theme,
                        selection: $selectedAction,
                        items: viewModel.multipleChoiceButtons
                    )
                    .onChange(of: selectedAction) { newAction in
                        onMultipleChoiceAction(newAction, viewModel.name)
                    }
                    if !viewModel.body.isEmpty {
                        bodyView
                        Spacer(minLength: UX.CardView.minContentSpacing)
                    }
                }
                .padding(UX.CardView.verticalPadding)
            }
            .scrollBounceBehavior(basedOnSize: true)

            VStack {
                primaryButton
                // Hidden spacer button to maintain consistent layout spacing
                // when secondary button is not present
                Button(" ", action: {})
                    .font(UX.CardView.secondaryActionFont)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .opacity(0)
                    .accessibilityHidden(true)
                    .disabled(true)
            }
            .padding(.bottom, UX.CardView.secondaryButtonBottomPadding)
        }
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFontForCurrentLocale)
            .foregroundColor(Color(theme.colors.textPrimary))
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .fixedSize(horizontal: false, vertical: true)
            .alignmentGuide(.titleAlignment) { dimensions in dimensions[.bottom] }
    }

    var bodyView: some View {
        Text(viewModel.body)
            .font(UX.CardView.bodyFont)
            .foregroundColor(Color(theme.colors.textSecondary))
            .multilineTextAlignment(UX.CardView.textAlignmentForCurrentLocale)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)DescriptionLabel")
    }

    var primaryButton: some View {
        OnboardingPrimaryButton(
            title: viewModel.buttons.primary.title,
            action: {
                onBottomButtonAction(
                    viewModel.buttons.primary.action,
                    viewModel.name
                )
            },
            theme: theme,
            accessibilityIdentifier: "\(viewModel.a11yIdRoot)PrimaryButton"
        )
        .frame(maxWidth: UX.CardView.primaryButtonWidthiPad)
    }
}
