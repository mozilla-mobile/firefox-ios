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
            cardContent(geometry: geometry)
                .onAppear {
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
                .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
                    guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
        }
    }
    
    @ViewBuilder
    private func cardContent(geometry: GeometryProxy) -> some View {
        ScrollView(showsIndicators: false) {
            VStack {
                titleView
                    .padding(.top, UX.CardView.titleCompactTopPadding)
                
                Spacer()
                OnboardingSegmentedControl<ViewModel.OnboardingMultipleChoiceActionType>(
                    selection: $selectedAction,
                    items: viewModel.multipleChoiceButtons
                )
                .onChange(of: selectedAction) { newAction in
                    onMultipleChoiceAction(newAction, viewModel.name)
                }
                Spacer()
                VStack(spacing: UX.CardView.buttonsSpacing) {
                    primaryButton
                    // Hidden spacer button to maintain consistent layout spacing
                    // when secondary button is not present
                    Button(" ", action: {})
                        .font(UX.CardView.secondaryActionFont)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .opacity(0)
                        .accessibilityHidden(true)
                        .disabled(true)
                }
                .padding(.bottom, UX.CardView.buttonsBottomPadding)
            }
            .padding(.horizontal, UX.CardView.cardHorizontalPadding)
            .frame(minHeight: geometry.size.height, maxHeight: .infinity, alignment: .center)
        }
        .scrollBounceBehavior(basedOnSize: true)
        .bridge.cardBackground(cardBackgroundColor, cornerRadius: UX.CardView.cornerRadius)
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
            .fixedSize(horizontal: false, vertical: true)
    }

    var primaryButton: some View {
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

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        cardBackgroundColor = Color(color.layer2)
    }
}
