// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

// TODO: - FXIOS-13874 sync ipad layout with iPhone
struct OnboardingViewRegular<ViewModel: OnboardingCardInfoModelProtocol>: ThemeableView {
    @State var theme: Theme
    @StateObject private var viewModel: OnboardingFlowViewModel<ViewModel>

    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        viewModel: OnboardingFlowViewModel<ViewModel>
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AnimatedGradientView(windowUUID: windowUUID, themeManager: themeManager)
                .edgesIgnoringSafeArea(.all)
            SheetSizedCard {
                VStack {
                    tabView
                    pageControl
                }
                .cardBackground(theme: theme, cornerRadius: UX.CardView.cornerRadius)
            }
            Button(action: viewModel.skipOnboarding) {
                Text(viewModel.skipText)
                    .bold()
                    .foregroundColor(Color(theme.colors.textOnDark))
            }
            .padding(.trailing, UX.Onboarding.Spacing.standard)
            .skipButtonStyle(theme: theme)
        }
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    private var tabView: some View {
        TabView(selection: $viewModel.pageCount) {
            ForEach(Array(viewModel.onboardingCards.enumerated()), id: \.element.name) { index, card in
                OnboardingCardViewRegular(
                    viewModel: card,
                    windowUUID: windowUUID,
                    themeManager: themeManager,
                    onBottomButtonAction: viewModel.handleBottomButtonAction,
                    onMultipleChoiceAction: viewModel.handleMultipleChoiceAction
                )
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }

    private var pageControl: some View {
        CustomPageControl(
            currentPage: $viewModel.pageCount,
            numberOfPages: viewModel.onboardingCards.count,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        .padding(.bottom)
    }
}
