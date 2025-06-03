// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

public struct OnboardingMultipleChoiceCardView<VM: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    @State private var selectedAction: VM.OnboardingMultipleChoiceActionType

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    public let viewModel: VM
    public let onBottomButtonAction: (VM.OnboardingActionType, String) -> Void
    public let onMultipleChoiceAction: (VM.OnboardingMultipleChoiceActionType, String) -> Void
    public let onLinkTap: (String) -> Void

    public init?(
        viewModel: VM,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onBottomButtonAction: @escaping (VM.OnboardingActionType, String) -> Void,
        onMultipleChoiceAction: @escaping (VM.OnboardingMultipleChoiceActionType, String) -> Void,
        onLinkTap: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onBottomButtonAction = onBottomButtonAction
        self.onMultipleChoiceAction = onMultipleChoiceAction
        self.onLinkTap = onLinkTap
        guard let firstAction = viewModel.multipleChoiceButtons.first?.action else {
            return nil
        }
        _selectedAction = State(initialValue: firstAction)
    }

    public var body: some View {
        GeometryReader { geometry in
            // Determine scale factor based on current size vs base metrics
            let widthScale = geometry.size.width / UX.CardView.baseWidth
            let heightScale = geometry.size.height / UX.CardView.baseHeight
            let scale = min(widthScale, heightScale)

            ScrollView {
                VStack {
                    VStack(spacing: UX.CardView.spacing * scale) {
                        Spacer()
                        titleView
                        Spacer()
                        OnboardingSegmentedControl<VM.OnboardingMultipleChoiceActionType>(
                            selection: $selectedAction,
                            items: viewModel.multipleChoiceButtons,
                            windowUUID: windowUUID,
                            themeManager: themeManager
                        )
                        .onChange(of: selectedAction) { newAction in
                            onMultipleChoiceAction(newAction, viewModel.name)
                        }
                        Spacer()
                        primaryButton
                    }
                    .frame(height: geometry.size.height * UX.CardView.cardHeightRatio)
                    .padding(UX.CardView.verticalPadding * scale)
                    .background(
                        RoundedRectangle(cornerRadius: UX.CardView.cornerRadius)
                            .fill(cardBackgroundColor)
                    )
                    .padding(.horizontal, UX.CardView.horizontalPadding * scale)
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
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UX.CardView.titleFont)
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
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
