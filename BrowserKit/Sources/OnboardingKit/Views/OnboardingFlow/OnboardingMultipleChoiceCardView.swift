// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingMultipleChoiceCardView<ViewModel: OnboardingCardInfoModelProtocol>: ThemeableView {
    @State var theme: Theme
    @State private var selectedAction: ViewModel.OnboardingMultipleChoiceActionType
    @Environment(\.sizeCategory)
    var sizeCategory
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let viewModel: ViewModel
    let variant: OnboardingVariant
    let onBottomButtonAction: (ViewModel.OnboardingActionType, String) -> Void
    let onMultipleChoiceAction: (ViewModel.OnboardingMultipleChoiceActionType, String) -> Void

    init?(
        viewModel: ViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        variant: OnboardingVariant,
        selectedAction: ViewModel.OnboardingMultipleChoiceActionType?,
        onBottomButtonAction: @escaping (ViewModel.OnboardingActionType, String) -> Void,
        onMultipleChoiceAction: @escaping (ViewModel.OnboardingMultipleChoiceActionType, String) -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.variant = variant
        self.onBottomButtonAction = onBottomButtonAction
        self.onMultipleChoiceAction = onMultipleChoiceAction
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
        guard let initialAction = selectedAction ?? viewModel.defaultSelectedButton?.action else {
            return nil
        }
        _selectedAction = State(initialValue: initialAction)
    }

    var body: some View {
        cardContent
            .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    private var cardContent: some View {
        OnboardingCardLayout { _ in
            VStack {
                titleView
                    .padding(.top, UX.CardView.titleCompactTopPadding)

                Spacer(minLength: UX.CardView.minContentSpacing)
                segmentedControl
                Spacer(minLength: UX.CardView.minContentSpacing)
                if !viewModel.body.isEmpty {
                    bodyView
                    Spacer(minLength: UX.CardView.minContentSpacing)
                }
            }
        } buttons: {
            primaryButton
                .padding(.bottom, UX.CardView.buttonsBottomPadding)
        }
        .if(horizontalSizeClass != .regular) { view in
            view.cardBackground(theme: theme, cornerRadius: UX.CardView.cornerRadius, variant: variant)
        }
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFont())
            .foregroundColor(theme.colors.textPrimary.color)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .if(sizeCategory <= .extraExtraLarge) { view in
                view.frame(height: UX.CardView.titleAlignmentMinHeightPadding, alignment: .topLeading)
            }
            .fixedSize(horizontal: false, vertical: true)
    }

    var bodyView: some View {
        Text(viewModel.body)
            .font(UX.CardView.bodyFont)
            .foregroundColor(theme.colors.textSecondary.color)
            .multilineTextAlignment(UX.CardView.textAlignment())
            .lineLimit(nil)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)DescriptionLabel")
    }

    var segmentedControl: some View {
        OnboardingSegmentedControl<ViewModel.OnboardingMultipleChoiceActionType>(
            theme: theme,
            variant: variant,
            selection: $selectedAction,
            items: viewModel.multipleChoiceButtons,
            a11yIdRoot: viewModel.a11yIdRoot
        )
        .onChange(of: selectedAction) { newAction in
            onMultipleChoiceAction(newAction, viewModel.name)
        }
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
            accessibilityIdentifier: "\(viewModel.a11yIdRoot)PrimaryButton",
            variant: variant
        )
        .if(horizontalSizeClass == .regular) { view in
            view.frame(maxWidth: UX.CardView.primaryButtonWidthiPad)
        }
    }
}
