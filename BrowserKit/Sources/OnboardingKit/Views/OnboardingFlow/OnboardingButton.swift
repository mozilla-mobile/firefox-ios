// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

extension View {
    @ViewBuilder
    func primaryButtonStyle(theme: Theme, variant: OnboardingVariant) -> some View {
        let buttonColor = primaryButtonColor(theme: theme, variant: variant)

        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .tint(buttonColor.color)
                .font(UX.CardView.primaryActionGlassFont)
                .foregroundStyle(theme.colors.textInverted.color)
        } else {
            self.buttonStyle(.borderless)
                .background(buttonColor.color)
                .font(UX.CardView.primaryActionFont)
                .foregroundStyle(theme.colors.textInverted.color)
        }
    }

    private func primaryButtonColor(theme: Theme, variant: OnboardingVariant) -> UIColor {
        return theme.colors.actionPrimary
    }

    @ViewBuilder
    func secondaryButtonStyle(theme: Theme) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .font(UX.CardView.primaryActionGlassFont)
                .tint(theme.colors.actionSecondary.color)
                .foregroundStyle(theme.colors.textSecondary.color)
        } else {
            self.buttonStyle(.borderless)
                .background(theme.colors.actionSecondary.color)
                .font(UX.CardView.primaryActionFont)
                .foregroundStyle(theme.colors.textSecondary.color)
        }
    }

    @ViewBuilder
    func skipButtonStyle(theme: Theme, variant: OnboardingVariant) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .tint(theme.colors.layer2.color)
                .foregroundStyle(theme.colors.textSecondary.color)
        } else {
            let textColor = variant == .brandRefresh
                ? theme.colors.textSecondary.color
                : theme.colors.iconOnColor.color
            self.buttonStyle(.borderless)
                .foregroundStyle(textColor)
        }
    }

    @ViewBuilder
    func cardBackground(theme: Theme, cornerRadius: CGFloat = 0.0, variant: OnboardingVariant? = nil) -> some View {
        let backgroundColor = theme.colors.layer2.color

        if #available(iOS 26, *), variant != .brandRefresh {
            self.glassEffect(.clear.interactive().tint(backgroundColor.opacity(0.95)),
                             in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .accessibilityHidden(true)
            )
        }
    }

    @ViewBuilder
    func backgroundClipShape() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonBorderShape(.roundedRectangle(radius: UX.Button.glassCornerRadius))
        } else {
            self.clipShape(RoundedRectangle(cornerRadius: UX.Button.cornerRadius))
        }
    }

    @ViewBuilder
    func paddedVersion(_ inset: Edge.Set, old: CGFloat, new: CGFloat) -> some View {
        if #available(iOS 26, *) {
            self.padding(inset, new)
        } else {
            self.padding(inset, old)
        }
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void
    let theme: Theme
    let accessibilityIdentifier: String
    let variant: OnboardingVariant

    var body: some View {
        Button(action: {
            action()
            UIAccessibility.post(notification: .announcement, argument: title)
        }, label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .paddedVersion(.vertical, old: UX.Button.verticalPadding, new: UX.Button.verticalGlassPadding)
                .padding(.horizontal, UX.Button.horizontalPadding)
        })
        .accessibilityLabel(title)
        .accessibility(identifier: accessibilityIdentifier)
        .primaryButtonStyle(theme: theme, variant: variant)
        .backgroundClipShape()
    }
}

struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void
    let theme: Theme
    let accessibilityIdentifier: String

    var body: some View {
        Button(action: {
            action()
            UIAccessibility.post(notification: .announcement, argument: title)
        }, label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .paddedVersion(.vertical, old: UX.Button.verticalPadding, new: UX.Button.verticalGlassPadding)
                .padding(.horizontal, UX.Button.horizontalPadding)
        })
        .accessibilityLabel(title)
        .accessibility(identifier: accessibilityIdentifier)
        .secondaryButtonStyle(theme: theme)
        .backgroundClipShape()
    }
}
