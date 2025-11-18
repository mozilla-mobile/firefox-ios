// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingBasicCardViewRegular<ViewModel: OnboardingCardInfoModelProtocol>: ThemeableView {
    @State var theme: Theme

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let viewModel: ViewModel
    let onBottomButtonAction: (ViewModel.OnboardingActionType, String) -> Void

    init(
        viewModel: ViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onBottomButtonAction: @escaping (ViewModel.OnboardingActionType, String) -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onBottomButtonAction = onBottomButtonAction
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: UX.CardView.regularSizeSpacing) {
                    titleView
                        .padding(.top, UX.CardView.titleTopPadding)
                    imageView
                    bodyView
                }
                .padding(UX.CardView.verticalPadding)
            }
            .scrollBounceBehavior(basedOnSize: true)
            VStack {
                primaryButton
                secondaryButton
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
    }

    @ViewBuilder var imageView: some View {
        if let img = viewModel.image {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: min(img.size.height, UX.CardView.maxImageHeight))
                .accessibilityHidden(true)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)ImageView")
        }
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

    @ViewBuilder var secondaryButton: some View {
        if let secondary = viewModel.buttons.secondary {
            OnboardingSecondaryButton(
                title: secondary.title,
                action: {
                    onBottomButtonAction(
                        secondary.action,
                        viewModel.name
                    )
                },
                theme: theme,
                accessibilityIdentifier: "\(viewModel.a11yIdRoot)SecondaryButton"
            )
            .frame(maxWidth: UX.CardView.primaryButtonWidthiPad)
        }
    }
}
