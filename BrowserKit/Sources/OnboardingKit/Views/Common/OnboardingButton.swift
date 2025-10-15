// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary


private extension UIColor {
    var color: Color {
        return Color(uiColor: self)
    }
}

private extension View {
    @ViewBuilder
    func primaryButtonStyle(theme: Theme) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .font(UX.CardView.primaryActionGlassFont)
        } else {
            self.buttonStyle(.borderless)
                .background(theme.colors.actionPrimary.color)
                .font(UX.CardView.primaryActionFont)
                .foregroundStyle(theme.colors.textInverted.color)
        }
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
    func backgroundClipShape() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonBorderShape(.roundedRectangle(radius: UX.Button.glassCornerRadius))
        } else {
            self.clipShape(RoundedRectangle(cornerRadius: UX.Button.cornerRadius))
        }
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void
    let theme: Theme
    let accessibilityIdentifier: String

    var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(title)
                .padding(.vertical, UX.Button.verticalPadding)
                .padding(.horizontal, UX.Button.horizontalPadding)
                .frame(maxWidth: .infinity)
        })
        .accessibility(identifier: accessibilityIdentifier)
        .primaryButtonStyle(theme: theme)
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
        }, label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, UX.Button.verticalPadding)
                .padding(.horizontal, UX.Button.horizontalPadding)
        })
        .accessibility(identifier: accessibilityIdentifier)
        .secondaryButtonStyle(theme: theme)
        .backgroundClipShape()
    }
}
