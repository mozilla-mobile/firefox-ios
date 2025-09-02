// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

public struct TermsOfServiceRegularView<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var secondaryTextColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear

    @StateObject private var viewModel: TosFlowViewModel<ViewModel>
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    public let onEmbededLinkAction: (TosAction) -> Void

    public init(
        viewModel: TosFlowViewModel<ViewModel>,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onEmbededLinkAction: @escaping (TosAction) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onEmbededLinkAction = onEmbededLinkAction
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            AnimatedGradientMetalView(windowUUID: windowUUID, themeManager: themeManager)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            termsContent
                .onAppear {
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
                .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
                    guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
        }
    }

    // MARK: - Main Content

    private var termsContent: some View {
        SheetSizedCard {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack {
                        VStack(spacing: UX.CardView.tosSpacing) {
                            VStack(spacing: UX.CardView.spacing) {
                                imageView
                                titleView
                                bodyView
                            }
                            VStack(spacing: UX.CardView.spacing) {
                                links
                                primaryButton
                            }
                        }
                        .padding(.vertical, UX.CardView.verticalPadding)
                        .frame(width: UX.CardView.primaryButtonWidthiPad)
                    }
                    .frame(width: geometry.size.width)
                    .frame(minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(basedOnSize: true)
            }
            .background(
                RoundedRectangle(
                    cornerRadius: UX.CardView.cornerRadius
                )
                .fill(cardBackgroundColor)
                .accessibilityHidden(true)
            )
            .padding(.horizontal, UX.CardView.horizontalPadding)
            .accessibilityElement(children: .contain)
        }
    }

    // MARK: - Subviews

    var links: some View {
        VStack(alignment: .center, spacing: UX.Onboarding.Spacing.standard) {
            ForEach(Array(viewModel.configuration.embededLinkText.enumerated()), id: \.element.linkText) { index, link in
                AttributedLinkText<TosAction>(
                    theme: themeManager.getCurrentTheme(for: windowUUID),
                    fullText: link.fullText,
                    linkText: link.linkText,
                    action: link.action,
                    linkAction: viewModel.handleEmbededLinkAction(action:)
                )
            }
        }
    }

    @ViewBuilder var imageView: some View {
        if let img = viewModel.configuration.image {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.CardView.tosImageHeight)
                .accessibilityHidden(true)
                .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)ImageView")
        }
    }

    var titleView: some View {
        Text(viewModel.configuration.title)
            .font(UX.CardView.titleFont)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)TitleLabel")
            .accessibilityLabel(viewModel.configuration.title)
            .accessibility(addTraits: .isHeader)
    }

    var bodyView: some View {
        Text(viewModel.configuration.body)
            .fixedSize(horizontal: false, vertical: true)
            .font(UX.CardView.bodyFont)
            .foregroundColor(secondaryTextColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)DescriptionLabel")
            .accessibilityLabel(viewModel.configuration.body)
    }

    var primaryButton: some View {
        Button(
            viewModel.configuration.buttons.primary.title,
            action: {
                viewModel.handleEmbededLinkAction(
                    action: .accept
                )
            }
        )
        .font(UX.CardView.primaryActionFont)
        .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)PrimaryButton")
        .buttonStyle(PrimaryButtonStyle(theme: themeManager.getCurrentTheme(for: windowUUID)))
    }

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        secondaryTextColor = Color(color.textSecondary)
        cardBackgroundColor = Color(color.layer2)
    }
}
