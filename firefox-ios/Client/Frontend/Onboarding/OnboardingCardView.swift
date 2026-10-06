// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common
import Shared

/// View that presents the day's onboarding cards
struct OnboardingFlowView: View, ThemeableView {
    private struct UX {
        static let bodyPadding: CGFloat = 0
        static let hiddenOpacity: CGFloat = 0
        static let radialGradientCentre = UnitPoint(x: 0.9, y: 0.1)
        static let radialGradientStartRadius: CGFloat = 0
        static let radialGradientEndRadius: CGFloat = 200
        static let radialGradientOrangeOpacity: CGFloat = 0.28
        static let linearGradientYellowOpacity: CGFloat = 0.25
        static let linearGradientPurpleOpacity: CGFloat = 0.2
    }

    private let cards: [OnboardingCard]
    private let onAction: (OnboardingCardButtonAction) -> Void
    private let onComplete: () -> Void
    @State var theme: Theme
    var windowUUID: WindowUUID
    var themeManager: ThemeManager

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
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
        self.onAction = onAction
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
        }
        .padding(UX.bodyPadding)
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    private var gradient: some View {
        let colors = gradientColors(for: theme)
        let radialGradient = RadialGradient(colors: [colors[safe: 2] ?? Color.clear, .white.opacity(UX.hiddenOpacity)],
                                            center: UX.radialGradientCentre,
                                            startRadius: UX.radialGradientStartRadius,
                                            endRadius: UX.radialGradientEndRadius)

        let linearGradient = LinearGradient(colors: Array(colors.prefix(2)),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing)
            .overlay(radialGradient)

        return linearGradient
    }

    // returns an array of colours needed for the card gradient
    private func gradientColors(for theme: Theme) -> [Color] {
        guard !theme.isNova else {
            let gradient = theme.colors.gradientAccentSubtle.colors
            // resolvedGradient is here incase gradientAccentSubtle changes for whatever reason
            let resolvedGradient = gradient.count == 2 ? gradient : [UIColor.clear, UIColor.clear]
            let isDark = theme.type == .dark
            let orange = theme.colors.gradientAIStrongStop3.color.opacity(UX.radialGradientOrangeOpacity)
            if isDark {
                return [Color(resolvedGradient[0]), Color(resolvedGradient[1]).opacity(UX.hiddenOpacity), orange]
            }
            return [Color(resolvedGradient[0]), Color(resolvedGradient[1]), orange]
        }

        let isDark = theme.type == .dark
        let yellowOpacity = isDark ? UX.hiddenOpacity : UX.linearGradientYellowOpacity
        let yellow = theme.colors.gradientAIStrongStop3.color.opacity(yellowOpacity)
        let purple = theme.colors.gradientAIStrongStop1.color.opacity(UX.linearGradientPurpleOpacity)
        let orange = theme.colors.gradientOnboardingStop4.color.opacity(UX.radialGradientOrangeOpacity)
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
    private struct UX {
        static let maxImageHeight: CGFloat = 500
        static let titleLineSpacing: CGFloat = 2

        static let imageBottomPadding: CGFloat = 4
        static let titleBottomPadding: CGFloat = 2
        static let bodyBottomPadding: CGFloat = 2
        static let buttonsTopSpacing: CGFloat = 90
        static let contentHorizontalPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 24

        static let titleHorizontalPadding: CGFloat = 56
        static let bodyHorizontalPadding: CGFloat = 24

        static let buttonSpacing: CGFloat = 12
        static let buttonsHorizontalPadding: CGFloat = 26
        static let buttonCornerRadius: CGFloat = 28
        static let primaryButtonVerticalPadding: CGFloat = 14
        static let secondaryButtonVerticalPadding: CGFloat = 15
    }

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
            cardImage
                .padding(.bottom, UX.imageBottomPadding)
            titleText
                .padding(.bottom, UX.titleBottomPadding)
            bodyText
                .padding(.bottom, UX.bodyBottomPadding)
            Spacer(minLength: UX.buttonsTopSpacing)
            buttons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, UX.contentHorizontalPadding)
        .padding(.bottom, UX.contentBottomPadding)
    }

    @ViewBuilder
    private var cardImage: some View {
        if let name = card.imageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: UX.maxImageHeight)
                .accessibilityHidden(true)
        }
    }

    private var titleText: some View {
        Text(card.title.replaceFirstOccurrence(of: "%@", with: AppName.shortName.rawValue))
            .font(FXFontStyles.Bold.largeTitle.scaledSwiftUIFont())
            .foregroundColor(theme.colors.textPrimary.color)
            .multilineTextAlignment(.center)
            .lineSpacing(UX.titleLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .accessibility(addTraits: .isHeader)
            .padding(.horizontal, UX.titleHorizontalPadding)
    }

    private var bodyText: some View {
        Text(card.body.replaceFirstOccurrence(of: "%@", with: AppName.shortName.rawValue))
            .font(FXFontStyles.Regular.title2.scaledSwiftUIFont())
            .foregroundColor(theme.colors.textSecondary.color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, UX.bodyHorizontalPadding)
    }

    private var buttons: some View {
        VStack(spacing: UX.buttonSpacing) {
            primaryButton
            secondaryButton
        }
        .padding(.horizontal, UX.buttonsHorizontalPadding)
    }

    private var primaryButton: some View {
        Button(action: onPrimary) {
            Text(card.primaryButtonTitle)
                .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                .foregroundColor(theme.colors.textInverted.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, UX.primaryButtonVerticalPadding)
        }
        .background(buttonColour)
        .clipShape(RoundedRectangle(cornerRadius: UX.buttonCornerRadius))
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryTitle = card.secondaryButtonTitle, let onSecondary = onSecondary {
            Button(action: onSecondary) {
                Text(secondaryTitle)
                    .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                    .foregroundColor(buttonColour)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, UX.secondaryButtonVerticalPadding)
            }
        }
    }
}
