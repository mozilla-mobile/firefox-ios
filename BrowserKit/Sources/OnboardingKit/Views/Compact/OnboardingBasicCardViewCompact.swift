// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

// MARK: - Updated OnboardingBasicCardViewCompact
struct OnboardingBasicCardViewCompact<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var secondaryTextColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
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
            cardContent(geometry: geometry)
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
    private func cardContent(geometry: GeometryProxy) -> some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: UX.CardView.spacing) {
                    titleView
                        .padding(.top, UX.CardView.titleTopPadding(for: geometry.size.height))
                    imageView
                    bodyView
                    Spacer()
                }
                .padding(.horizontal, UX.CardView.horizontalPadding)
            }
            .scrollBounceBehavior(basedOnSize: true)

            VStack {
                primaryButton
                secondaryButton
            }
            .padding(UX.CardView.verticalPadding)
        }
        .bridge.cardBackground(cardBackgroundColor, cornerRadius: UX.CardView.cornerRadius)
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFont)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .if(sizeCategory <= .large) { view in
                view.frame(minHeight: UX.CardView.titleAlignmentMinHeightPadding, alignment: .topLeading)
            }
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    var imageView: some View {
        if let img = viewModel.image {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.CardView.imageHeight)
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
    }

    var primaryButton: some View {
        Group {
            if #available(iOS 17.0, *) {
                OnboardingButton.primary(
                    viewModel.buttons.primary.title,
                    action: {
                        onBottomButtonAction(
                            viewModel.buttons.primary.action,
                            viewModel.name
                        )
                    },
                    accessibilityIdentifier: "\(viewModel.a11yIdRoot)PrimaryButton",
                    windowUUID: windowUUID,
                    themeManager: themeManager
                )
            } else {
                DragCancellablePrimaryButton(
                    title: viewModel.buttons.primary.title,
                    action: {
                        onBottomButtonAction(
                            viewModel.buttons.primary.action,
                            viewModel.name
                        )
                    },
                    theme: themeManager.getCurrentTheme(for: windowUUID),
                    accessibilityIdentifier: "\(viewModel.a11yIdRoot)PrimaryButton"
                )
            }
        }
    }

    @ViewBuilder
    var secondaryButton: some View {
        if let secondary = viewModel.buttons.secondary {
            Group {
                if #available(iOS 17.0, *) {
                    OnboardingButton.secondary(
                        secondary.title,
                        action: {
                            onBottomButtonAction(
                                secondary.action,
                                viewModel.name
                            )
                        },
                        accessibilityIdentifier: "\(viewModel.a11yIdRoot)SecondaryButton",
                        windowUUID: windowUUID,
                        themeManager: themeManager
                    )
                } else {
                    DragCancellableSecondaryButton(
                        title: secondary.title,
                        action: {
                            onBottomButtonAction(
                                secondary.action,
                                viewModel.name
                            )
                        },
                        theme: themeManager.getCurrentTheme(for: windowUUID),
                        accessibilityIdentifier: "\(viewModel.a11yIdRoot)SecondaryButton"
                    )
                }
            }
        }
    }

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        secondaryTextColor = Color(color.textSecondary)
        cardBackgroundColor = Color(color.layer2)
    }
}
