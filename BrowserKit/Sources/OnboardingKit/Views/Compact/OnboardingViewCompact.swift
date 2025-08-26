// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingViewCompact<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @StateObject private var viewModel: OnboardingFlowViewModel<ViewModel>
    @State private var maxTitleHeight: CGFloat = 0
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
            VStack {
                PagingCarousel(
                    selection: $viewModel.pageCount,
                    items: viewModel.onboardingCards
                ) { card in
                    OnboardingCardViewCompact(
                        maxTitleHeight: $maxTitleHeight,
                        viewModel: card,
                        windowUUID: windowUUID,
                        themeManager: themeManager,
                        onBottomButtonAction: viewModel.handleBottomButtonAction,
                        onMultipleChoiceAction: viewModel.handleMultipleChoiceAction
                    )
                }
                // Uses preference keys to find the maximum title height across all carousel cards,
                // then applies that height to all title containers for consistent image positioning
                .onPreferenceChange(TitleHeightPreferenceKey.self) { height in
                    print(maxTitleHeight, height)
                    maxTitleHeight = max(maxTitleHeight, height)
                }

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
        }
    }
}
