// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct OnboardingView<VM: OnboardingCardInfoModelProtocol>: View {
    @StateObject private var viewModel: OnboardingFlowViewModel<VM>
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    public init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        viewModel: OnboardingFlowViewModel<VM>
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    public var body: some View {
        ZStack {
            MilkyWayMetalView()
                .edgesIgnoringSafeArea(.all)
            TabView(selection: $viewModel.pageCount) {
                ForEach(Array(viewModel.onboardingCards.enumerated()), id: \.element.name) { index, card in
                    VStack {
                        OnboardingCardView(
                            viewModel: card,
                            windowUUID: windowUUID,
                            themeManager: themeManager,
                            onBottomButtonAction: viewModel.handleBottomButtonAction,
                            onMultipleChoiceAction: viewModel.handleMultipleChoiceAction,
                            onLinkTap: { _ in }
                        )
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}
