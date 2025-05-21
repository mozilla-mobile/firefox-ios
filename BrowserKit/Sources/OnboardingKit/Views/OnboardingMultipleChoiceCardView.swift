// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

public struct OnboardingMultipleChoiceCardView<VM: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    private var shadowColor = Color.black.opacity(UX.CardView.shadowOpacity)
    @State private var selectedAction: VM.OnboardingMultipleChoiceActionType

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    public let viewModel: VM
    public let onPrimaryActionTap: () -> Void
    public let onSecondaryActionTap: () -> Void
    public let onLinkTap: () -> Void

    public init(
        viewModel: VM,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onPrimaryActionTap: @escaping () -> Void,
        onSecondaryActionTap: @escaping () -> Void,
        onLinkTap: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimaryActionTap = onPrimaryActionTap
        self.onSecondaryActionTap = onSecondaryActionTap
        self.onLinkTap = onLinkTap
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self._selectedAction = State(initialValue: viewModel.multipleChoiceButtons.first!.action)
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
                        Spacer()
                        primaryButton
                    }
                    .frame(height: geometry.size.height * UX.CardView.cardHeightRatio)
                    .padding(UX.CardView.verticalPadding * scale)
                    .background(
                        RoundedRectangle(cornerRadius: UX.CardView.cornerRadius)
                            .fill(cardBackgroundColor)
                            .shadow(
                                color: shadowColor,
                                radius: UX.CardView.shadowRadius,
                                x: UX.CardView.shadowOffsetX,
                                y: UX.CardView.shadowOffsetY
                            )
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
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
    }
    
    var primaryButton: some View {
        Button(viewModel.buttons.primary.title, action: onPrimaryActionTap)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
            .buttonStyle(PrimaryButtonStyle(theme: themeManager.getCurrentTheme(for: windowUUID)))
    }
    
    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        cardBackgroundColor = Color(color.layer2)
    }
}
