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

            Button(action: skipOnboarding) {
                Text(viewModel.skipText)
                    .bold()
                    .foregroundColor(skipTextColor)
            }
            .padding(.trailing, UX.Onboarding.Spacing.standard)
            .bridge.glassButtonStyle()
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

    private func skipOnboarding() {
        let currentIndex = min(max(viewModel.pageCount, 0), viewModel.onboardingCards.count - 1)
        let currentCardName = viewModel.onboardingCards[currentIndex].name
        viewModel.onComplete(currentCardName)
    }

    private func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        skipTextColor = Color(theme.colors.textInverted)
    }
}
