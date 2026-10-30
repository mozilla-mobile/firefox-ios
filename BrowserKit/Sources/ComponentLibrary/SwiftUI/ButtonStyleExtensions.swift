// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

extension View {
    /// Full width button filled with the primary action color, liquid glass on iOS 26.
    @ViewBuilder
    public func primaryButtonStyle(theme: Theme) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(GlassPrimaryButtonStyle(theme: theme))
        } else {
            self.buttonStyle(LegacyPrimaryButtonStyle(theme: theme))
        }
    }
}

/// Wraps the label in a `.glassProminent` button, which already adds its own insets around the label.
@available(iOS 26.0, *)
private struct GlassPrimaryButtonStyle: PrimitiveButtonStyle {
    private struct UX {
        static let verticalPadding: CGFloat = 6
        static let horizontalPadding: CGFloat = 12
    }

    let theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
                .frame(maxWidth: .infinity)
                .padding(.vertical, UX.verticalPadding)
                .padding(.horizontal, UX.horizontalPadding)
        }
        .buttonStyle(.glassProminent)
        .tint(theme.colors.actionPrimary.color)
        .font(FXFontStyles.Bold.headline.scaledSwiftUIFont())
        .foregroundStyle(theme.colors.textInverted.color)
    }
}

/// Mirrors the configuration of `PrimaryRoundedButton`.
private struct LegacyPrimaryButtonStyle: ButtonStyle {
    private struct UX {
        static let verticalPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
    }

    @Environment(\.isEnabled) private var isEnabled
    let theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
            .foregroundStyle(foregroundColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, UX.verticalPadding)
            .padding(.horizontal, UX.horizontalPadding)
            .background(
                backgroundColor(isPressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: UX.cornerRadius)
            )
            .contentShape(RoundedRectangle(cornerRadius: UX.cornerRadius))
    }

    private var foregroundColor: Color {
        return isEnabled ? theme.colors.textInverted.color : theme.colors.textInvertedDisabled.color
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return theme.colors.actionPrimaryDisabled.color }
        return isPressed ? theme.colors.actionPrimaryHover.color : theme.colors.actionPrimary.color
    }
}
