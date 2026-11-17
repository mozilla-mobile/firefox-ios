// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

@available(iOS 17.0, *)
struct VPNSettingsViewContainer: ThemeableView {
    private enum UX {
        static let cardOuterPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 16
        static let footerTopSpacing: CGFloat = 8
    }

    @State var theme: Theme
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let viewModel: VPNSettingsViewModel
    // needed only for navigation from the Learn More button
    weak var viewController: VPNSettingsViewController?

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        viewModel: VPNSettingsViewModel,
        viewController: VPNSettingsViewController?
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.viewModel = viewModel
        self.viewController = viewController
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UX.cardSpacing) {
                settingsCard
                dataUsageSection
            }
            .padding(UX.cardOuterPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.layer1.color)
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    // MARK: - Sections

    private var settingsCard: some View {
        VPNHelpers.card(theme: theme) {
            VPNSettingsContentView(theme: theme, viewController: viewController)
            VPNHelpers.divider()
            VPNLocationsRow(windowUUID: windowUUID, themeManager: themeManager, viewModel: viewModel, theme: theme)
            VPNHelpers.divider()
            VPNToggleRow(viewModel: viewModel, theme: theme)
        }
    }

    private var dataUsageSection: some View {
        VStack(alignment: .leading, spacing: UX.footerTopSpacing) {
            VPNHelpers.card(theme: theme) {
                VPNUsageBar(viewModel: viewModel, theme: theme)
            }
            Text(String(
                format: .VPN.Settings.DataLimitResetFooter,
                VPNHelpers.formatted(gigabytes: viewModel.dataLimitInGB)
            ))
                .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.textSecondary.color)
                .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel(Text(String.VPN.Settings.DataLimitTitle))
        .accessibilityValue(VPNHelpers.usageAccessibilityText(
            usedDataInGB: viewModel.usedDataInGB,
            dataLimitInGB: viewModel.dataLimitInGB
        ))
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.dataUsage)
    }
}
