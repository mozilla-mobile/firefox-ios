// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

public struct TermsOfUseView<ViewModel: OnboardingCardInfoModelProtocol>: ThemeableView {
    @State public var theme: Theme
    @StateObject private var viewModel: TermsOfUseFlowViewModel<ViewModel>
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
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
                OnboardingBackgroundView(
                    windowUUID: windowUUID,
                    themeManager: themeManager,
                    variant: viewModel.variant
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )

                if horizontalSizeClass == .regular {
                    regularLayout
                } else {
                    compactLayout(geometry: geometry, scale: scale)
                }
            }
            .animation(.easeOut, value: geometry.size)
        }
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    // MARK: - Regular Layout

    private var regularLayout: some View {
        SheetSizedCard {
            regularContent
                .cardBackground(theme: theme, cornerRadius: UX.CardView.cornerRadius, variant: viewModel.variant)
        }
    }

    private var regularContent: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: UX.CardView.tosSpacing) {
                    VStack(spacing: UX.CardView.spacing) {
                        regularImageView
                        titleView
                    }
                    bodyView
                    VStack(spacing: UX.CardView.spacing) {
                        links
                        primaryButton
                            .frame(maxWidth: UX.CardView.primaryButtonWidthiPad)
                    }
                }
                .padding(.vertical, UX.CardView.verticalPadding)
                .frame(width: UX.CardView.primaryButtonWidthiPad)
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(basedOnSize: true)
        }
        .padding(.horizontal, UX.CardView.horizontalPadding)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var regularImageView: some View {
        if let img = imageForVariant {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.CardView.tosImageHeight(for: viewModel.variant))
                .accessibilityHidden(true)
                .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)ImageView")
        }
    }

    private var imageForVariant: UIImage? {
        return UX.Image.tosImage(for: viewModel.variant, fallback: viewModel.configuration.image)
    }

    // MARK: - Compact Layout

    private func compactLayout(geometry: GeometryProxy, scale: CGFloat) -> some View {
        VStack {
            compactContent(scale: scale)

            Spacer()
                .frame(height: UX.CardView.pageControlHeight)
                .padding(.bottom)
        }
        .padding(.top, UX.CardView.cardTopPadding)
    }

    private func compactContent(scale: CGFloat) -> some View {
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
        .cardBackground(theme: theme, cornerRadius: UX.CardView.cornerRadius, variant: viewModel.variant)
        .padding(.horizontal, UX.CardView.horizontalPadding * scale)
        .padding(.vertical)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Subviews

    var links: some View {
        VStack(
            alignment: UX.CardView.linksHorizontalAlignment(for: viewModel.variant),
            spacing: UX.Onboarding.Spacing.standard
        ) {
            ForEach(Array(viewModel.configuration.embededLinkText.enumerated()), id: \.element.linkText) { index, link in
                AttributedLinkText<TermsOfUseAction>(
                    textColor: theme.colors.textSecondary,
                    linkColor: linkColor,
                    fullText: link.fullText,
                    linkText: link.linkText,
                    action: link.action,
                    textAlignment: UX.CardView.linksTextAlignment(for: viewModel.variant),
                    linkAction: viewModel.handleEmbededLinkAction(action:)
                )
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var linkColor: UIColor {
        return theme.colors.actionPrimary
    }

    @ViewBuilder
    func imageView(scale: CGFloat) -> some View {
        if let img = imageForVariant {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.CardView.tosImageHeight(for: viewModel.variant) * scale)
                .accessibilityHidden(true)
                .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)ImageView")
        }
    }

    var titleView: some View {
        Text(viewModel.configuration.title)
            .font(UX.CardView.titleFont())
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
            .multilineTextAlignment(UX.CardView.textAlignment())
            .frame(maxWidth: .infinity, alignment: UX.CardView.frameAlignment())
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
            accessibilityIdentifier: "\(viewModel.configuration.a11yIdRoot)PrimaryButton",
            variant: viewModel.variant
        )
    }
}
