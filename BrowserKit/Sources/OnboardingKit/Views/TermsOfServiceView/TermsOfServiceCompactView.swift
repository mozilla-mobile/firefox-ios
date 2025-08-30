// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

public struct TermsOfServiceCompactView<ViewModel: OnboardingCardInfoModelProtocol>: View {
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
        GeometryReader { geometry in
            let widthScale = geometry.size.width / UX.CardView.baseWidth
            let heightScale = geometry.size.height / UX.CardView.baseHeight
            let scale = min(widthScale, heightScale)
            ZStack {
                AnimatedGradientMetalView(windowUUID: windowUUID, themeManager: themeManager)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                VStack {
                    cardContent(geometry: geometry, scale: scale)
                    Spacer()
                }
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
    }

    @ViewBuilder
    private func cardContent(geometry: GeometryProxy, scale: CGFloat) -> some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(spacing: UX.CardView.spacing * scale) {
                        Spacer()
                        imageView(scale: scale)
                        titleView
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
        .frame(height: geometry.size.height * UX.CardView.cardHeightRatio)
        .background(
            RoundedRectangle(cornerRadius: UX.CardView.cornerRadius)
                .fill(cardBackgroundColor)
                .accessibilityHidden(true)
        )
        .padding(.horizontal, UX.CardView.horizontalPadding * scale)
        .accessibilityElement(children: .contain)
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
            .font(UX.CardView.titleFont)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.configuration.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .fixedSize(horizontal: false, vertical: true)
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
