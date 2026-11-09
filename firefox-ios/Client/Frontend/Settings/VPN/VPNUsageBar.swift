// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

@available(iOS 17.0, *)
struct VPNUsageBar: View {
    let viewModel: VPNSettingsViewModel
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(String.VPN.Settings.DataLimitTitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Spacer()
                Text(VPNHelpers.usageText(
                    usedDataInGB: viewModel.usedDataInGB,
                    dataLimitInGB: viewModel.dataLimitInGB
                ))
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            ProgressView(value: viewModel.usageFraction)
                .tint(VPNHelpers.progressColor(usageFraction: viewModel.usageFraction, theme: theme))
        }
        .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
        .padding(.vertical, VPNHelpers.UX.rowVerticalPadding)
    }
}
