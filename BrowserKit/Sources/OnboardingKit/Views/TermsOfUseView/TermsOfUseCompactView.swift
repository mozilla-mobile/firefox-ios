// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

public struct TermsOfUseCompactView<ViewModel: OnboardingCardInfoModelProtocol>: ThemeableView {
    @State public var theme: Theme
    @StateObject private var viewModel: TermsOfUseFlowViewModel<ViewModel>
    public let windowUUID: WindowUUID
    public var themeManager: ThemeManager

    public init(
        viewModel: TermsOfUseFlowViewModel<ViewModel>,
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    // MARK: - Body
    public var body: some View {
        GeometryReader { geometry in
            let widthScale = geometry.size.width / UX.CardView.baseWidth
            let heightScale = geometry.size.height / UX.CardView.baseHeight
            let scale = min(widthScale, heightScale)
            ZStack {
                AnimatedGradientView(windowUUID: windowUUID, themeManager: themeManager)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                VStack {
                    cardContent(geometry: geometry, scale: scale)
                    Spacer()
                        .frame(height: UX.CardView.pageControlHeight)
                        .padding(.bottom)
                }
                .padding(.top, UX.CardView.cardTopPadding)
            }
            .animation(.easeOut, value: geometry.size)
        }
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    @ViewBuilder
    private func cardContent(geometry: GeometryProxy, scale: CGFloat) -> some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: UX.CardView.spacing * scale) {
                        Spacer()
                        VStack(spacing: UX.CardView.spacing * scale) {
                            imageView(scale: scale)
                            titleView
                        }
                        bodyView
                        Spacer()
                        links
                        Spacer()
                    }
                    .padding(UX.CardView.verticalPadding * scale)
                    .frame(width: geometry.size.width)
                    .frame(minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(basedOnSize: true)
            }
            primaryButton
                .padding(UX.CardView.verticalPadding * scale)
                .padding(.bottom)
        }
        .cardBackground(theme: theme, cornerRadius: UX.CardView.cornerRadius)
        .padding(.horizontal, UX.CardView.horizontalPadding * scale)
        .accessibilityElement(children: .contain)
        .padding(.vertical)
    }

    // MARK: - Subviews

    var links: some View {
        VStack(alignment: UX.CardView.horizontalAlignmentForCurrentLocale, spacing: UX.Onboarding.Spacing.standard) {
            ForEach(Array(viewModel.configuration.embededLinkText.enumerated()), id: \.element.linkText) { index, link in
                AttributedLinkText<TermsOfUseAction>(
                    theme: theme,
                    fullText: link.fullText,
                    linkText: link.linkText,
                    action: link.action,
                    textAlignment: UX.CardView.textAlignmentForCurrentLocale,
                    linkAction: viewModel.handleEmbededLinkAction(action:)
                )
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    func imageView(scale: CGFloat) -> some View {
        if let img = viewModel.configuration.image {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.CardView.tosImageHeight * scale)
                .accessibilityHidden(true)
                .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)ImageView")
        }
    }

    var titleView: some View {
        Text(viewModel.configuration.title)
            .font(UX.CardView.titleFontForCurrentLocale)
            .foregroundColor(Color(theme.colors.textPrimary))
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .fixedSize(horizontal: false, vertical: true)
    }

    var bodyView: some View {
        Text(viewModel.configuration.body)
            .fixedSize(horizontal: false, vertical: true)
            .font(UX.CardView.bodyFont)
            .foregroundColor(Color(theme.colors.textSecondary))
            .multilineTextAlignment(UX.CardView.textAlignmentForCurrentLocale)
            .frame(maxWidth: .infinity, alignment: UX.CardView.frameAlignmentForCurrentLocale)
            .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)DescriptionLabel")
            .accessibilityLabel(viewModel.configuration.body)
    }

    var primaryButton: some View {
        OnboardingPrimaryButton(
            title: viewModel.configuration.buttons.primary.title,
            action: {
                viewModel.handleEmbededLinkAction(
                    action: .accept
                )
            },
            theme: theme,
            accessibilityIdentifier: "\(viewModel.configuration.a11yIdRoot)PrimaryButton"
        )
    }
}
