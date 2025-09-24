// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingMultipleChoiceCardViewCompact<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    @State private var selectedAction: ViewModel.OnboardingMultipleChoiceActionType
    @Environment(\.sizeCategory)
    var sizeCategory

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let viewModel: ViewModel
    let onBottomButtonAction: (ViewModel.OnboardingActionType, String) -> Void
    let onMultipleChoiceAction: (ViewModel.OnboardingMultipleChoiceActionType, String) -> Void

    init?(
        viewModel: ViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onBottomButtonAction: @escaping (ViewModel.OnboardingActionType, String) -> Void,
        onMultipleChoiceAction: @escaping (ViewModel.OnboardingMultipleChoiceActionType, String) -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onBottomButtonAction = onBottomButtonAction
        self.onMultipleChoiceAction = onMultipleChoiceAction
        guard let defaultAction = viewModel.defaultSelectedButton?.action else {
            return nil
        }
        _selectedAction = State(initialValue: defaultAction)
    }

    var body: some View {
        GeometryReader { geometry in
            scrollViewContent(geometry: geometry)
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

    private func scrollViewContent(geometry: GeometryProxy) -> some View {
        VStack {
            ScrollView {
                VStack(spacing: UX.CardView.spacing) {
                    titleView
                        .padding(.top, UX.CardView.titleTopPadding)
                    OnboardingSegmentedControl<ViewModel.OnboardingMultipleChoiceActionType>(
                        selection: $selectedAction,
                        items: viewModel.multipleChoiceButtons,
                        windowUUID: windowUUID,
                        themeManager: themeManager
                    )
                    .onChange(of: selectedAction) { newAction in
                        onMultipleChoiceAction(newAction, viewModel.name)
                    }
                }
                .padding(.horizontal, UX.CardView.horizontalPadding)
            }
            .scrollBounceBehavior(basedOnSize: true)
            primaryButton
                .padding(UX.CardView.verticalPadding)
        }
        .frame(height: geometry.size.height * UX.CardView.cardHeightRatio)
        .background(
            RoundedRectangle(cornerRadius: UX.CardView.cornerRadius)
                .fill(cardBackgroundColor)
                .accessibilityHidden(true)
        )
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFont)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .if(sizeCategory <= .extraExtraLarge) { view in
                view.frame(height: UX.CardView.titleAlignmentMinHeightPadding, alignment: .topLeading)
            }
    }

    var primaryButton: some View {
        Group {
            if #available(iOS 17.0, *) {
                Button(
                    viewModel.buttons.primary.title,
                    action: {
                        onBottomButtonAction(
                            viewModel.buttons.primary.action,
                            viewModel.name
                        )
                    }
                )
                .font(UX.CardView.primaryActionFont)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
                .buttonStyle(PrimaryButtonStyle(theme: themeManager.getCurrentTheme(for: windowUUID)))
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

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        cardBackgroundColor = Color(color.layer2)
    }
}
