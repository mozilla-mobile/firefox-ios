// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

@available(iOS 17.0, *)
struct VPNToggleRow: View {
    let viewModel: VPNSettingsViewModel
    let theme: Theme

    var body: some View {
        Toggle(isOn: Binding(get: { viewModel.isVPNEnabled },
                             set: { viewModel.toggleVPN($0) })) {
            HStack {
                Text(String.VPN.Settings.ToggleTitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Spacer()
                if viewModel.isVPNConnecting {
                    VPNHelpers.loadingIndicator(text: .VPN.Settings.Connecting, theme: theme)
                        .accessibilityHidden(true)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: theme.colors.actionPrimary.color))
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.vpnToggle)
        .accessibilityValue(viewModel.accessibilityValue)
        .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
        .padding(.vertical, VPNHelpers.UX.rowVerticalPadding)
    }
}
