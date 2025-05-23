// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

public struct OnboardingBasicCardView<VM: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var secondaryTextColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    @State private var secondaryAction: Color = .clear

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    public let viewModel: VM
    public let onPrimaryActionTap: () -> Void
    public let onSecondaryActionTap: () -> Void
    public let onLinkTap: () -> Void

    public init(
        viewModel: VM,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onPrimaryActionTap: @escaping () -> Void,
        onSecondaryActionTap: @escaping () -> Void,
        onLinkTap: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimaryActionTap = onPrimaryActionTap
        self.onSecondaryActionTap = onSecondaryActionTap
        self.onLinkTap = onLinkTap
        self.themeManager = themeManager
        self.windowUUID = windowUUID
    }

    public var body: some View {
        GeometryReader { geometry in
            // Determine scale factor based on current size vs base metrics
            let widthScale = geometry.size.width / UX.CardView.baseWidth
            let heightScale = geometry.size.height / UX.CardView.baseHeight
            let scale = min(widthScale, heightScale)

            ScrollView {
                VStack {
                    VStack(spacing: UX.CardView.spacing * scale) {
                        Spacer()
                        titleView
                        imageView(scale: scale)
                        bodyView
                        linkView
                        Spacer()
                        primaryButton
                    }
                    .frame(height: geometry.size.height * UX.CardView.cardHeightRatio)
                    .padding(UX.CardView.verticalPadding * scale)
                    .background(
                        RoundedRectangle(cornerRadius: UX.CardView.cornerRadius)
                            .fill(cardBackgroundColor)
                    )
                    .padding(.horizontal, UX.CardView.horizontalPadding * scale)
                    secondaryButton(scale: scale)
                    Spacer()
                }
            }
            .onAppear {
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
                guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
        }
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFont)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
    }

    @ViewBuilder
    func imageView(scale: CGFloat) -> some View {
        if let img = viewModel.image {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.CardView.imageHeight * scale)
                .accessibilityLabel(viewModel.title)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)ImageView")
        }
    }

    var bodyView: some View {
        Text(viewModel.body)
            .font(UX.CardView.bodyFont)
            .foregroundColor(secondaryTextColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)DescriptionLabel")
    }

    @ViewBuilder var linkView: some View {
        if let linkVM = viewModel.link {
            LinkButtonView(
                viewModel: LinkInfoModel(
                    title: linkVM.title,
                    url: linkVM.url,
                    accessibilityIdentifier: "\(viewModel.a11yIdRoot)LinkButton"
                ),
                action: onLinkTap
            )
        }
    }

    var primaryButton: some View {
        Button(viewModel.buttons.primary.title, action: onPrimaryActionTap)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
            .buttonStyle(PrimaryButtonStyle(theme: themeManager.getCurrentTheme(for: windowUUID)))
    }

    @ViewBuilder
    func secondaryButton(scale: CGFloat) -> some View {
        if let secondary = viewModel.buttons.secondary {
            Button(secondary.title, action: onSecondaryActionTap)
                .foregroundColor(secondaryAction)
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
        secondaryAction = Color(color.textInverted)
    }
}
