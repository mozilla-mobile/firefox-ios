// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common

/// View that presents the day's onboarding cards
struct DripOnboardingFlowView: View {
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
        let card = cards[min(index, cards.count - 1)]
        let secondaryAction: (() -> Void)? = card.secondaryButtonTitle == nil
            ? nil
            : { perform(card.secondaryButtonAction) }

        ZStack {
            theme.colors.layer1.color
                .ignoresSafeArea()

            DripOnboardingCardView(
                card: card,
                theme: theme,
                onPrimary: { perform(card.primaryButtonAction) },
                onSecondary: secondaryAction
            )
        }
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

struct DripOnboardingCardView: View {
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
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            cardImage
            titleText
            bodyText
            Spacer(minLength: 0)
            buttons
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var cardImage: some View {
        if let name = card.imageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .accessibilityHidden(true)
        }
    }

    private var titleText: some View {
        Text(card.title)
            .font(FXFontStyles.Bold.title1.scaledSwiftUIFont())
            .foregroundColor(theme.colors.textPrimary.color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibility(addTraits: .isHeader)
    }

    private var bodyText: some View {
        Text(card.body)
            .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
            .foregroundColor(theme.colors.textSecondary.color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            primaryButton
            secondaryButton
        }
    }

    private var primaryButton: some View {
        Button(action: onPrimary) {
            Text(card.primaryButtonTitle)
                .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                .foregroundColor(theme.colors.textInverted.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(theme.colors.actionPrimary.color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryTitle = card.secondaryButtonTitle, let onSecondary = onSecondary {
            Button(action: onSecondary) {
                Text(secondaryTitle)
                    .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                    .foregroundColor(theme.colors.actionPrimary.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
        }
    }
}
