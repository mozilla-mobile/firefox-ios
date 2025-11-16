// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

// MARK: - Updated OnboardingBasicCardViewCompact
struct OnboardingBasicCardViewCompact<ViewModel: OnboardingCardInfoModelProtocol>: ThemeableView {
    @State var theme: Theme
    @Environment(\.sizeCategory)
    private var sizeCategory

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
        GeometryReader { geometry in
            cardContent(geometry: geometry)
        }
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    @ViewBuilder
    private func cardContent(geometry: GeometryProxy) -> some View {
        ScrollView(showsIndicators: false) {
            VStack {
                titleView
                    .padding(.top, UX.CardView.titleCompactTopPadding)

                Spacer(minLength: UX.CardView.minContentSpacing)
                VStack(spacing: UX.CardView.contentSpacing) {
                    imageView(geometry: geometry)
                    bodyView
                }
                Spacer(minLength: UX.CardView.minContentSpacing)
                VStack(spacing: UX.CardView.buttonsSpacing) {
                    primaryButton
                    secondaryButton
                }
                .padding(.bottom, UX.CardView.buttonsBottomPadding)
            }
            .padding(.horizontal, UX.CardView.cardHorizontalPadding)
            .frame(minHeight: geometry.size.height, maxHeight: .infinity, alignment: .center)
        }
        .scrollBounceBehavior(basedOnSize: true)
        .cardBackground(theme: theme, cornerRadius: UX.CardView.cornerRadius)
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFontForCurrentLocale)
            .foregroundColor(theme.colors.textPrimary.color)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .if(sizeCategory <= .large) { view in
                view.frame(minHeight: UX.CardView.titleAlignmentMinHeightPadding, alignment: .topLeading)
            }
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    func imageView(geometry: GeometryProxy) -> some View {
        if let img = viewModel.image {
            let imgHeight = min(img.size.height, geometry.size.height * 0.4)
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: imgHeight)
                .accessibilityHidden(true)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)ImageView")
        }
    }

    var bodyView: some View {
        Text(viewModel.body)
            .font(UX.CardView.bodyFont)
            .foregroundColor(theme.colors.textSecondary.color)
            .multilineTextAlignment(UX.CardView.textAlignmentForCurrentLocale)
            .lineLimit(nil)
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
    }

    @ViewBuilder
    var secondaryButton: some View {
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
        }
    }
}
