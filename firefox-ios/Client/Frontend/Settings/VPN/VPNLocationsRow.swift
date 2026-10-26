// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

@available(iOS 17.0, *)
struct VPNLocationsRow: View {
    let viewModel: VPNSettingsViewModel
    let theme: Theme
    weak var viewController: VPNSettingsViewController?

    var body: some View {
        Button {
            viewController?.locationsTapped()
        } label: {
            HStack {
                Text(String.VPN.Settings.LocationTitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Spacer()
                Text(viewModel.locationName)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textSecondary.color)
                Image(StandardImageIdentifiers.Large.chevronRight)
                    .renderingMode(.template)
                    .foregroundStyle(theme.colors.iconSecondary.color)
                    .flipsForRightToLeftLayoutDirection(true)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
            .padding(.vertical, VPNHelpers.UX.rowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String.VPN.Settings.LocationTitle)
        .accessibilityValue(viewModel.locationName)
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.locationSetting)
    }
}
