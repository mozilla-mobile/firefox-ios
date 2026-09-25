// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI
import UIKit

/// Homepage card prompting the user to enable notifications
struct NotificationCardView: View {
    let theme: Theme
    let onEnable: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(alignment: .top) {
                Image(ImageIdentifiers.Onboarding.ContinuousOnboarding.notificationCard)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 56)
                    .accessibilityHidden(true)
                    .padding([.bottom, .trailing, .top], 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(String.Onboarding.MultiDay.HomeScreenNotificationsPopup.Title)
                        .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                        .foregroundColor(theme.colors.textPrimary.color)
                        .padding(.top, 8)

                    Text(String.Onboarding.MultiDay.HomeScreenNotificationsPopup.BodyText
                        .replaceFirstOccurrence(of: "%@", with: AppName.shortName.rawValue))
                        .font(FXFontStyles.Regular.subheadline.scaledSwiftUIFont())
                        .foregroundColor(theme.colors.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: false)
                }
                closeButton
                    .padding([.leading], 16)
            }
            enableNotificationsButton
                .padding(.top, 12)
        }
        .padding(16)
        .background(theme.colors.layer4.color)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: theme.colors.shadowSubtle.color, radius: 8, x: 0, y: 4)
        .frame(maxWidth: 650)
    }

    var enableNotificationsButton: some View {
        let buttonTextColor = Color(red: 0xB3 / 255, green: 0x93 / 255, blue: 0xFF / 255)
        let buttonBGOpacity = theme.type == .dark ? 0.08 : 0.15
        let buttonBGColor = buttonTextColor.opacity(buttonBGOpacity)
        return Button(action: onEnable) {
            Text(String.Onboarding.MultiDay.HomeScreenNotificationsPopup.EnableButtonText)
                .font(FXFontStyles.Bold.callout.scaledSwiftUIFont())
                .foregroundColor(buttonTextColor)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: 400)
        .background(buttonBGColor)
        .clipShape(Capsule())
    }

    var closeButton: some View {
        let iconColor = theme.type == .dark ?
            theme.colors.iconOnColor.color.opacity(0.7) :
            theme.colors.iconPrimary.color.opacity(0.5)
        let buttonOpacity = theme.type == .dark ? 0.2 : 0.1
        let buttonColor = theme.colors.iconPrimary.color.opacity(buttonOpacity)
        return Button(action: onClose) {
            ZStack {
                Circle()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(buttonColor)

                Image(uiImage: UIImage(named: StandardImageIdentifiers.Medium.cross) ?? UIImage())
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(iconColor)
            }
        }
        .accessibilityLabel("Close")
    }
}
