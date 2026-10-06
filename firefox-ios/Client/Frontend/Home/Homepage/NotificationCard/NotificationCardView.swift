// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI
import UIKit

/// Homepage card prompting the user to enable notifications
struct NotificationCardView: View, ThemeableView {
    private struct UX {
        static let cardSpacing: CGFloat = 8
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 24
        static let cardMaxWidth: CGFloat = 650
        static let shadowRadius: CGFloat = 8
        static let shadowOffsetY: CGFloat = 4
        static let iconMaxHeight: CGFloat = 56
        static let iconPadding: CGFloat = 8
        static let textSpacing: CGFloat = 8
        static let titleTopPadding: CGFloat = 8
        static let enableButtonTopPadding: CGFloat = 12
        static let enableButtonVerticalPadding: CGFloat = 14
        static let enableButtonHorizontalPadding: CGFloat = 12
        static let enableButtonMaxWidth: CGFloat = 400
        static let enableButtonBackgroundOpacity: CGFloat = 0.08
        static let closeButtonLeadingPadding: CGFloat = 16
        static let closeButtonSize: CGFloat = 30
        static let closeIconSize: CGFloat = 20
        static let closeButtonDarkOpacity: CGFloat = 0.2
        static let closeButtonLightOpacity: CGFloat = 0.1
        static let closeIconDarkOpacity: CGFloat = 0.7
        static let closeIconLightOpacity: CGFloat = 0.5
    }

    @State var theme: Theme
    var windowUUID: WindowUUID
    var themeManager: ThemeManager
    let onEnable: () -> Void
    let onClose: () -> Void

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onEnable: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
        self.onEnable = onEnable
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .center, spacing: UX.cardSpacing) {
            HStack(alignment: .top) {
                Image(decorative: ImageIdentifiers.Onboarding.ContinuousOnboarding.notificationCard)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: UX.iconMaxHeight)
                    .padding([.bottom, .trailing, .top], UX.iconPadding)

                VStack(alignment: .leading, spacing: UX.textSpacing) {
                    Text(String.Onboarding.MultiDay.HomeScreenNotificationsPopup.Title)
                        .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                        .foregroundColor(theme.colors.textPrimary.color)
                        .padding(.top, UX.titleTopPadding)

                    Text(String.Onboarding.MultiDay.HomeScreenNotificationsPopup.BodyText
                        .replaceFirstOccurrence(of: "%@", with: AppName.shortName.rawValue))
                        .font(FXFontStyles.Regular.subheadline.scaledSwiftUIFont())
                        .foregroundColor(theme.colors.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: false)
                }
                closeButton
                    .padding(.leading, UX.closeButtonLeadingPadding)
            }
            enableNotificationsButton
                .padding(.top, UX.enableButtonTopPadding)
        }
        .padding(UX.cardPadding)
        .background(theme.colors.layer4.color)
        .clipShape(RoundedRectangle(cornerRadius: UX.cardCornerRadius))
        .shadow(color: theme.colors.shadowSubtle.color, radius: UX.shadowRadius, x: 0, y: UX.shadowOffsetY)
        .frame(maxWidth: UX.cardMaxWidth)
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    private var enableButtonColour: Color {
        theme.isNova ? theme.colors.textAccent.color : theme.colors.gradientAIStrongStop1.color
    }

    // TODO: get rid of this once nova is the default
    private var enableButtonOpacity: CGFloat {
        theme.isNova ? UX.enableButtonBackgroundOpacity : 0.12
    }

    private var enableNotificationsButton: some View {
        return Button(action: onEnable) {
            Text(String.Onboarding.MultiDay.HomeScreenNotificationsPopup.EnableButtonText)
                .font(FXFontStyles.Bold.body.scaledSwiftUIFont())
                .foregroundColor(enableButtonColour)
                .padding(.vertical, UX.enableButtonVerticalPadding)
                .padding(.horizontal, UX.enableButtonHorizontalPadding)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: UX.enableButtonMaxWidth)
        .background(enableButtonColour.opacity(enableButtonOpacity))
        .clipShape(Capsule())
    }

    private var closeButton: some View {
        let iconColor = theme.type == .dark ?
            theme.colors.iconOnColor.color.opacity(UX.closeIconDarkOpacity) :
            theme.colors.iconPrimary.color.opacity(UX.closeIconLightOpacity)
        let buttonOpacity = theme.type == .dark ? UX.closeButtonDarkOpacity : UX.closeButtonLightOpacity
        let buttonColor = theme.colors.iconPrimary.color.opacity(buttonOpacity)
        return Button(action: onClose) {
            ZStack {
                Circle()
                    .scaledToFit()
                    .frame(width: UX.closeButtonSize, height: UX.closeButtonSize)
                    .foregroundColor(buttonColor)

                Image(StandardImageIdentifiers.Medium.cross)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UX.closeIconSize, height: UX.closeIconSize)
                    .foregroundColor(iconColor)
            }
        }
        .accessibilityLabel(String.Onboarding.MultiDay.HomeScreenNotificationsPopup.AccessibilityCloseButtonText)
    }
}
