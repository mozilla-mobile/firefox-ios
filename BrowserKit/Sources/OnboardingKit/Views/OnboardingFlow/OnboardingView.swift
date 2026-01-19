// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

// MARK: - Main Onboarding View
public struct OnboardingView<ViewModel: OnboardingCardInfoModelProtocol>: ThemeableView {
    @StateObject private var viewModel: OnboardingFlowViewModel<ViewModel>
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    public let windowUUID: WindowUUID
    public var themeManager: ThemeManager
    @State public var theme: Theme

    public init(
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

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundGradient
                if horizontalSizeClass == .regular {
                    regularLayout
                } else {
                    compactLayout(geometry: geo)
                }
            }
            .animation(.easeOut, value: geo.size)
        }
        .accessibilityElement(children: .contain)
        .listenToThemeChanges(
            theme: $theme,
            manager: themeManager,
            windowUUID: windowUUID
        )
        .onAppear {
            viewModel.handlePageChange()
        }
        .onChange(of: viewModel.pageCount) { _ in
            viewModel.handlePageChange()
        }
    }

    private var regularLayout: some View {
        ZStack(alignment: .topTrailing) {
            SheetSizedCard {
                VStack {
                    tabView
                    pageControl
                        .padding(.bottom)
                }
                .cardBackground(
                    theme: theme,
                    cornerRadius: UX.CardView.cornerRadius
                )
            }
            .accessibilityScrollAction { edge in
                handleAccessibilityScroll(from: edge)
            }

            skipButton
                .padding(.top, UX.Onboarding.Spacing.standard)
                .padding(.trailing, UX.Onboarding.Spacing.standard)
        }
    }

    // MARK: - Compact Layout

    private func compactLayout(geometry: GeometryProxy) -> some View {
        VStack {
            skipButton
                .padding(.trailing, UX.Onboarding.Spacing.standard)
                .frame(maxWidth: .infinity, alignment: .trailing)

            tabView

            Spacer()

            compactPageControl
                .padding(
                    .bottom,
                    pageControllPadding(
                        safeAreaBottomInset: geometry.safeAreaInsets.bottom
                    )
                )
        }
        .accessibilityScrollAction { edge in
            handleAccessibilityScroll(from: edge)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private var backgroundGradient: some View {
        AnimatedGradientView(windowUUID: windowUUID, themeManager: themeManager)
            .ignoresSafeArea()
    }

    private var skipButton: some View {
        Button(action: viewModel.skipOnboarding) {
            Text(viewModel.skipText)
                .font(FXFontStyles.Bold.body.scaledSwiftUIFont(sizeCap: UX.Onboarding.Font.skipButtonSizeCap))
        }
        .skipButtonStyle(theme: theme)
        .accessibilityLabel(viewModel.skipText)
    }

    private var tabView: some View {
        TabView(selection: $viewModel.pageCount) {
            ForEach(Array(viewModel.onboardingCards.enumerated()), id: \.element.name) { index, card in
                cardView(for: card)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }

    private func cardView(for card: ViewModel) -> some View {
        OnboardingCardView(
            viewModel: card,
            windowUUID: windowUUID,
            themeManager: themeManager,
            onBottomButtonAction: handleBottomButtonAction,
            onMultipleChoiceAction: viewModel.handleMultipleChoiceAction
        )
        .if(horizontalSizeClass != .regular) { view in
            view
                .padding(.top, UX.CardView.cardTopPadding)
                .padding(.bottom, UX.CardView.cardBottomPadding)
                .padding(.horizontal, UX.CardView.horizontalPadding)
        }
    }

    private var pageControl: some View {
        CustomPageControl(
            currentPage: $viewModel.pageCount,
            numberOfPages: viewModel.onboardingCards.count,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
    }

    private var compactPageControl: some View {
        CustomPageControl(
            currentPage: $viewModel.pageCount,
            numberOfPages: viewModel.onboardingCards.count,
            windowUUID: windowUUID,
            themeManager: themeManager,
            style: .compact
        )
    }

    private func pageControllPadding(safeAreaBottomInset: CGFloat) -> CGFloat {
        safeAreaBottomInset == 0
            ? UX.CardView.carouselDotBottomPadding
            : safeAreaBottomInset * 0.5
    }

    private func handleAccessibilityScroll(from edge: Edge) {
        switch edge {
        case .leading:
            viewModel.scrollToPreviousPage()
            postAccessibilityNotification()
        case .trailing:
            viewModel.scrollToNextPage()
            postAccessibilityNotification()
        default:
            break
        }
    }

    private func postAccessibilityNotification() {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }

    private func handleBottomButtonAction(action: ViewModel.OnboardingActionType, card: String) {
        viewModel.handleBottomButtonAction(action: action, cardName: card)
        if action.rawValue.contains("forward") {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }
}
