// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

private struct LocalUX {
    static let horizontalPadding: CGFloat = 24.0
}

struct OnboardingViewCompact<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @StateObject private var viewModel: OnboardingFlowViewModel<ViewModel>
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    @State private var theme: Theme

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
        GeometryReader { geo in
            ZStack {
                AnimatedGradientView(windowUUID: windowUUID, themeManager: themeManager)
                    .ignoresSafeArea()
                VStack {
                    Button(action: viewModel.skipOnboarding) {
                        Text(viewModel.skipText)
                            .font(FXFontStyles.Bold.body.scaledSwiftUIFont(sizeCap: UX.Onboarding.Font.skipButtonSizeCap))
                    }
                    .padding(.trailing, UX.Onboarding.Spacing.standard)
                    .skipButtonStyle(theme: theme)
                    .accessibilitySortPriority(2)
                    .accessibilityLabel(viewModel.skipText)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    tabView
                        .accessibilitySortPriority(1)
                        .accessibilityElement(children: .contain)

                    Spacer()

                    CustomPageControl(
                        currentPage: $viewModel.pageCount,
                        numberOfPages: viewModel.onboardingCards.count,
                        windowUUID: windowUUID,
                        themeManager: themeManager,
                        style: .compact
                    )
                    .padding(.bottom, pageControllPadding(safeAreaBottomInset: geo.safeAreaInsets.bottom))
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .onAppear {
            applyTheme()
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            withAnimation {
                applyTheme()
            }
        }
    }

    private var tabView: some View {
        TabView(selection: $viewModel.pageCount) {
            ForEach(Array(viewModel.onboardingCards.enumerated()), id: \.element.name) { index, card in
                OnboardingCardViewCompact(
                    viewModel: card,
                    windowUUID: windowUUID,
                    themeManager: themeManager,
                    onBottomButtonAction: handleBottomButtonAction,
                    onMultipleChoiceAction: viewModel.handleMultipleChoiceAction
                )
                .tag(index)
                .padding(.top, UX.CardView.cardTopPadding)
                .padding(.bottom, UX.CardView.cardBottomPadding)
                .padding(.horizontal, UX.CardView.horizontalPadding)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .accessibilityElement(children: .contain)
        .accessibilityScrollAction { edge in
            if edge == .leading {
                viewModel.pageCount -= 1
            } else if edge == .trailing {
                viewModel.pageCount += 1
            }
        }
    }

    private func pageControllPadding(safeAreaBottomInset: CGFloat) -> CGFloat {
        if safeAreaBottomInset == 0 {
            return UX.CardView.carouselDotBottomPadding
        }
        return safeAreaBottomInset * 0.5
    }
    
    private func handleBottomButtonAction(action: ViewModel.OnboardingActionType, card: String) {
        viewModel.handleBottomButtonAction(action: action, cardName: card)
        if action.rawValue.contains("forward") {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }
    
    // MARK: - Theme

    private func applyTheme() {
        theme = themeManager.getCurrentTheme(for: windowUUID)
    }
}
