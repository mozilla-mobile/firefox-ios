// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

// MARK: - Updated OnboardingBasicCardView
struct OnboardingBasicCardView<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var secondaryTextColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    @State private var secondaryActionColor: Color = .clear
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
    }

    var body: some View {
        GeometryReader { geometry in
            let widthScale = geometry.size.width / UX.CardView.baseWidth
            let heightScale = geometry.size.height / UX.CardView.baseHeight
            let scale = min(widthScale, heightScale)

            cardContent(scale: scale, geometry: geometry)
                .padding(.top, UX.CardView.cardTopPadding)
                .onAppear {
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
                .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
                    guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
        }
    }

    @ViewBuilder
    private func cardContent(scale: CGFloat, geometry: GeometryProxy) -> some View {
        VStack(spacing: UX.CardView.cardSecondaryContainerPadding(for: sizeCategory)) {
            ContentFittingScrollView {
                VStack(spacing: UX.CardView.spacing * scale) {
                    Spacer()
                    titleView
                    Spacer()
                    imageView(scale: scale)
                    Spacer()
                    bodyView
                    Spacer()
                    primaryButton
                }
            }
            .frame(height: geometry.size.height * UX.CardView.cardHeightRatio)
            .padding(UX.CardView.verticalPadding * scale)
            .background(
                RoundedRectangle(cornerRadius: UX.CardView.cornerRadius)
                    .fill(cardBackgroundColor)
                    .accessibilityHidden(true)
            )
            secondaryButton(scale: scale)
            Spacer()
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

    @ViewBuilder
    func imageView(scale: CGFloat) -> some View {
        if let img = viewModel.image {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.CardView.imageHeight * scale)
                .accessibilityHidden(true)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)ImageView")
        }
    }

    var bodyView: some View {
        Text(viewModel.body)
            .font(UX.CardView.bodyFont)
            .foregroundColor(secondaryTextColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)DescriptionLabel")
            .alignmentGuide(.descriptionAlignment) { dimensions in dimensions[.bottom] }
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
    }

    @ViewBuilder
    func secondaryButton(scale: CGFloat) -> some View {
        if let secondary = viewModel.buttons.secondary {
            Button(
                secondary.title,
                action: {
                    onBottomButtonAction(
                        secondary.action,
                        viewModel.name
                    )
                })
            .font(UX.CardView.secondaryActionFont)
            .foregroundColor(secondaryActionColor)
            .padding(.top, UX.CardView.secondaryButtonTopPadding * scale)
            .padding(.bottom, UX.CardView.secondaryButtonBottomPadding * scale)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)SecondaryButton")
        }
    }

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        secondaryTextColor = Color(color.textSecondary)
        cardBackgroundColor = Color(color.layer2)
        secondaryActionColor = Color(color.textInverted)
    }
}
