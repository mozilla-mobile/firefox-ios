// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingMultipleChoiceCardView<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    @State private var selectedAction: ViewModel.OnboardingMultipleChoiceActionType

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
        // Determine scale factor based on current size vs base metrics
        let widthScale = geometry.size.width / UX.CardView.baseWidth
        let heightScale = geometry.size.height / UX.CardView.baseHeight
        let scale = min(widthScale, heightScale)

        return VStack {
            ContentFittingScrollView {
                VStack(spacing: UX.CardView.spacing * scale) {
                    Spacer()
                    titleView
                    Spacer()
                    OnboardingSegmentedControl<ViewModel.OnboardingMultipleChoiceActionType>(
                        selection: $selectedAction,
                        items: viewModel.multipleChoiceButtons,
                        windowUUID: windowUUID,
                        themeManager: themeManager
                    )
                    .alignmentGuide(.descriptionAlignment) { dimensions in dimensions[.bottom] }
                    .onChange(of: selectedAction) { newAction in
                        onMultipleChoiceAction(newAction, viewModel.name)
                    }
                    Spacer()
                    primaryButton
                }
            }
            .frame(height: geometry.size.height * UX.CardView.cardHeightRatio)
            .padding(UX.CardView.verticalPadding * scale)
            .background(
                RoundedRectangle(cornerRadius: UX.CardView.cornerRadius)
                    .fill(cardBackgroundColor)
                    .accessibilityHidden(true)
            )
            .padding(.top, UX.CardView.cardTopPadding)
        }
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFont)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
            .fixedSize(horizontal: false, vertical: true)
            .alignmentGuide(.titleAlignment) { dimensions in dimensions[.bottom] }
    }

    var primaryButton: some View {
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
    }

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        cardBackgroundColor = Color(color.layer2)
    }
}
