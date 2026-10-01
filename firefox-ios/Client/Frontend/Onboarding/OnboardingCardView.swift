// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common

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
        return ZStack(alignment: .topTrailing) {
            let theme = themeManager.getCurrentTheme(for: windowUUID)
            let card = cards[min(index, cards.count - 1)]
            let secondaryAction: (() -> Void)? = card.secondaryButtonTitle == nil
            ? nil
            : { perform(card.secondaryButtonAction) }

            theme.colors.layer1.color
                .ignoresSafeArea()

            gradient
                .ignoresSafeArea()

            OnboardingCardView(
                card: card,
                theme: theme,
                onPrimary: { perform(card.primaryButtonAction) },
                onSecondary: secondaryAction
            )
        }.padding(0)
    }

    private var gradient: some View {
        let colors = gradientColors(for: themeManager.getCurrentTheme(for: windowUUID))
        let center = UnitPoint(x: 0.9, y: 0.1)
        let radialGradient = RadialGradient(colors: [colors[2], .white.opacity(0)],
                                            center: center,
                                            startRadius: 0,
                                            endRadius: 200)

        let linearGradient = LinearGradient(colors: Array(colors[0...1]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing)
            .overlay(radialGradient)

        return linearGradient
    }

    // returns an array of colours needed for the card gradient
    private func gradientColors(for theme: Theme) -> [Color] {
        guard !theme.isNova else {
            let gradient = theme.colors.gradientAccentSubtle.colors
            let orange = theme.colors.gradientAIStrongStop3.color.opacity(0.28)
            return [Color(gradient[0]), Color(gradient[1]), orange]
        }

        let isDark = theme.type == .dark
        let yellowOpacity = isDark ? 0.0 : 0.25
        let yellow = theme.colors.gradientAIStrongStop3.color.opacity(yellowOpacity)
        let purple = theme.colors.gradientAIStrongStop1.color.opacity(0.2)
        let orange = theme.colors.gradientOnboardingStop4.color.opacity(0.28)
        return [purple, yellow, orange]
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

    private var buttonColour: Color {
        theme.isNova ? theme.colors.actionPrimary.color : theme.colors.gradientAIStrongStop1.color
    }

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
        if let name = theme.type == .dark ? card.darkImageName : card.lightImageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 500)
                .accessibilityHidden(true)
        }
    }

    private var titleText: some View {
        Text(card.title.replaceFirstOccurrence(of: "%@", with: "Firefox"))
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
        Text(card.body.replaceFirstOccurrence(of: "%@", with: "Firefox"))
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
        .background(buttonColour)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryTitle = card.secondaryButtonTitle, let onSecondary = onSecondary {
            Button(action: onSecondary) {
                Text(secondaryTitle)
                    .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                    .foregroundColor(buttonColour)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
        }
    }
}
