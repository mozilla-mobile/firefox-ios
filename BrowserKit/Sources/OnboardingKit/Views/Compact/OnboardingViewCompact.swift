// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingViewCompact<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @StateObject private var viewModel: OnboardingFlowViewModel<ViewModel>
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    @State private var skipTextColor: Color = .clear

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        viewModel: OnboardingFlowViewModel<ViewModel>
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AnimatedGradientMetalView(windowUUID: windowUUID, themeManager: themeManager)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Group {
                    pagingCarousel
                }
                .padding(.vertical)

                Spacer()

                CustomPageControl(
                    currentPage: $viewModel.pageCount,
                    numberOfPages: viewModel.onboardingCards.count,
                    windowUUID: windowUUID,
                    themeManager: themeManager,
                    style: .compact
                )
                .padding(.bottom)
            }
            .accessibilitySortPriority(1)
            .accessibilityElement(children: .contain)

            Button(action: viewModel.skipOnboarding) {
                Text(viewModel.skipText)
                    .font(FXFontStyles.Bold.body.scaledSwiftUIFont(sizeCap: UX.Onboarding.Font.skipButtonSizeCap))
                    .foregroundColor(skipTextColor)
            }
            .padding(.trailing, UX.Onboarding.Spacing.standard)
            .bridge.glassButtonStyle()
            .accessibilitySortPriority(2)
            .accessibilityLabel(viewModel.skipText)
        }
        .onAppear {
            applyTheme()
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme()
        }
    }

    private var pagingCarousel: some View {
        PagingCarousel(
            selection: $viewModel.pageCount,
            items: viewModel.onboardingCards,
            disableInteractionDuringTransition: false
        ) { card in
            OnboardingCardViewCompact(
                viewModel: card,
                windowUUID: windowUUID,
                themeManager: themeManager,
                onBottomButtonAction: viewModel.handleBottomButtonAction,
                onMultipleChoiceAction: viewModel.handleMultipleChoiceAction
            )
        }
    }

    private func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        skipTextColor = Color(theme.colors.textOnDark)
    }
}
