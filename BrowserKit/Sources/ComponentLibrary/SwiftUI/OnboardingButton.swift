// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct OnboardingButton: View {
    @State private var backgroundColor: Color = .clear
    @State private var foregroundColor: Color = .clear
    let title: String
    let action: () -> Void
    let accessibilityIdentifier: String
    let buttonType: ButtonType
    let width: CGFloat?
    let windowUUID: WindowUUID
    let themeManager: ThemeManager

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
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self.title = title
        self.action = action
        self.accessibilityIdentifier = accessibilityIdentifier
        self.buttonType = buttonType
        self.width = width
        self.windowUUID = windowUUID
        self.themeManager = themeManager
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: width ?? .infinity)
                .foregroundColor(foregroundColor)
        }
        .accessibility(identifier: accessibilityIdentifier)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(backgroundColor)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    private func applyTheme(theme: Theme) {
        let colors = theme.colors

        switch buttonType {
        case .primary:
            backgroundColor = Color(colors.actionPrimary)
            foregroundColor = Color(colors.textInverted)
        case .secondary:
            backgroundColor = Color(colors.actionSecondary)
            foregroundColor = Color(colors.textSecondary)
        }
    }

    public static func primary(
        _ title: String,
        action: @escaping () -> Void,
        accessibilityIdentifier: String,
        width: CGFloat? = nil,
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) -> OnboardingButton {
        OnboardingButton(
            title: title,
            action: action,
            accessibilityIdentifier: accessibilityIdentifier,
            buttonType: .primary,
            width: width,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
    }

    public static func secondary(
        _ title: String,
        action: @escaping () -> Void,
        accessibilityIdentifier: String,
        width: CGFloat? = nil,
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) -> OnboardingButton {
        OnboardingButton(
            title: title,
            action: action,
            accessibilityIdentifier: accessibilityIdentifier,
            buttonType: .secondary,
            width: width,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
    }
}
