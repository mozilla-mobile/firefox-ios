// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

struct OnboardingViewRegular<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @State private var cardBackgroundColor: Color = .clear
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
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    var body: some View {
        ZStack {
            AnimatedGradientMetalView(windowUUID: windowUUID, themeManager: themeManager)
                .edgesIgnoringSafeArea(.all)
            SheetSizedCard {
                VStack {
                    tabView
                    pageControl
                }
                .background(
                    RoundedRectangle(cornerRadius: UX.CardView.cornerRadius)
                        .fill(cardBackgroundColor)
                )
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

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        cardBackgroundColor = Color(color.layer2)
    }
}
