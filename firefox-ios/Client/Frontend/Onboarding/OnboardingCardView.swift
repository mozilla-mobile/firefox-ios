// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common
import Shared

/// View that presents the day's onboarding cards
struct OnboardingFlowView: View {
    private let cards: [OnboardingCard]
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let onAction: (OnboardingCardButtonAction) -> Void
    private let onComplete: () -> Void

    @State private var index = 0

    init(
        cards: [OnboardingCard],
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onAction: @escaping (OnboardingCardButtonAction) -> Void = { _ in },
        onComplete: @escaping () -> Void
    ) {
        self.cards = cards
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onAction = onAction
        self.onComplete = onComplete
    }

    var body: some View {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let isDark = theme.type == .dark
        let card = cards[min(index, cards.count - 1)]
        let secondaryAction: (() -> Void)? = card.secondaryButtonTitle == nil
            ? nil
            : { perform(card.secondaryButtonAction) }

        let yellowOpacity = isDark ? 0.0 : 0.25
        let yellow = Color(red: 0xFF / 255, green: 0xD4 / 255, blue: 0xB7 / 255, opacity: yellowOpacity)
        // let purple = Color(red: 0xE5 / 255, green: 0xD6 / 255, blue: 0xFF / 255, opacity: 0.35)
        let purple = theme.colors.gradientAIStrongStop1.color.opacity(0.2)
        // let red = Color(red: 0xFF / 255, green: 0x8F / 255, blue: 0x5D / 255, opacity: 0.28)
        let red = Color.red.opacity(0.2)
        ZStack {
            theme.colors.layer1.color
                .ignoresSafeArea()

            if #available(iOS 18.0, *) {
                MeshGradient(width: 2,
                             height: 2,
                             points: [.init(0, 0), .init(1, 0), .init(0, 1), .init(1, 1)],
                             colors: [purple, red, yellow, yellow])
                .ignoresSafeArea()
            } else {
                LinearGradient(colors: [purple, .yellow],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .opacity(0.15)
                .ignoresSafeArea()
            }

            OnboardingCardView(
                card: card,
                theme: theme,
                onPrimary: { perform(card.primaryButtonAction) },
                onSecondary: secondaryAction
            )
        }.padding(0)
    }

    private func perform(_ action: OnboardingCardButtonAction) {
        onAction(action)
        advance()
    }

    private func advance() {
        if index + 1 < cards.count {
            index += 1
        } else {
            onComplete()
        }
    }
}

struct OnboardingCardView: View {
    private let card: OnboardingCard
    private let theme: Theme
    private let onPrimary: () -> Void
    private let onSecondary: (() -> Void)?

    init(
        card: OnboardingCard,
        theme: Theme,
        onPrimary: @escaping () -> Void,
        onSecondary: (() -> Void)?
    ) {
        self.card = card
        self.theme = theme
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
    }

    var body: some View {
        VStack {
            cardImage.padding([.bottom], 4)
            titleText.padding([.top], 0).padding([.bottom], 2)
            bodyText.padding([.bottom], 2)
            Spacer(minLength: 90)
            buttons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding([.leading, .trailing], 16)
        .padding([.bottom], 24)
    }

    @ViewBuilder
    private var cardImage: some View {
        if let name = card.imageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 500)
                .accessibilityHidden(true)
        }
    }

    private var titleText: some View {
        Text(card.title.replaceFirstOccurrence(of: "%@", with: AppName.shortName.rawValue))
            .font(FXFontStyles.Bold.largeTitle.scaledSwiftUIFont())
            .foregroundColor(theme.colors.textPrimary.color)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .accessibility(addTraits: .isHeader)
            .padding([.leading, .trailing], 56)
            .padding([.top, .bottom], 0)
    }

    private var bodyText: some View {
        Text(card.body.replaceFirstOccurrence(of: "%@", with: AppName.shortName.rawValue))
            .font(FXFontStyles.Regular.title2.scaledSwiftUIFont())
            .foregroundColor(theme.colors.textSecondary.color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding([.leading, .trailing], 24)
            .padding([.top, .bottom], 0)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            primaryButton
            secondaryButton
        }
        .padding([.leading, .trailing], 26)
    }

    private var primaryButton: some View {
        Button(action: onPrimary) {
            Text(card.primaryButtonTitle)
                .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                .foregroundColor(theme.colors.textInverted.color)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 50))
                .padding([.top, .bottom], 14)
                .padding([.leading, .trailing], 0)
        }
        .padding(0)
        .background(theme.colors.gradientAIStrongStop1.color)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryTitle = card.secondaryButtonTitle, let onSecondary = onSecondary {
            Button(action: onSecondary) {
                Text(secondaryTitle)
                    .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                    .foregroundColor(theme.colors.gradientAIStrongStop1.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
        }
    }
}
