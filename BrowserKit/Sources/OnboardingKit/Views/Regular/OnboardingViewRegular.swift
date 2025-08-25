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

#Preview {
    SheetSizedCard {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top)

            Spacer()

            Image(systemName: "doc.plaintext")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Sheet Sized Card")
                .font(.title2)
                .fontWeight(.bold)

            Text("This card automatically sizes to match iPad sheet dimensions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button("Sample Button") {
                print("Button tapped")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
    .background(Color(.systemGray6))
}
