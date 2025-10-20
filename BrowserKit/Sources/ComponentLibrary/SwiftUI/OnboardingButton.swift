// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct OnboardingButton: View {
    let title: String
    let action: () -> Void
    let accessibilityIdentifier: String
    let buttonType: ButtonType
    let width: CGFloat?
    let theme: Theme

    public enum ButtonType {
        case primary
        case secondary
    }

    init(
        title: String,
        action: @escaping () -> Void,
        accessibilityIdentifier: String,
        buttonType: ButtonType,
        width: CGFloat? = nil,
        theme: Theme
    ) {
        self.title = title
        self.action = action
        self.accessibilityIdentifier = accessibilityIdentifier
        self.buttonType = buttonType
        self.width = width
        self.theme = theme
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: width ?? .infinity)
                .foregroundColor(
                    buttonType == .primary ? Color(theme.colors.textInverted) : Color(theme.colors.textSecondary)
                )
        }
        .accessibility(identifier: accessibilityIdentifier)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(
            buttonType == .primary ? Color(theme.colors.actionPrimary) : Color(theme.colors.actionSecondary)
        )
    }

    public static func primary(
        _ title: String,
        action: @escaping () -> Void,
        accessibilityIdentifier: String,
        width: CGFloat? = nil,
        theme: Theme
    ) -> OnboardingButton {
        OnboardingButton(
            title: title,
            action: action,
            accessibilityIdentifier: accessibilityIdentifier,
            buttonType: .primary,
            width: width,
            theme: theme
        )
    }

    public static func secondary(
        _ title: String,
        action: @escaping () -> Void,
        accessibilityIdentifier: String,
        width: CGFloat? = nil,
        theme: Theme
    ) -> OnboardingButton {
        OnboardingButton(
            title: title,
            action: action,
            accessibilityIdentifier: accessibilityIdentifier,
            buttonType: .secondary,
            width: width,
            theme: theme
        )
    }
}
