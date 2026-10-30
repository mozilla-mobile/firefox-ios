// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

// MARK: - View Container

struct VPNSettingsViewContainer: ThemeableView {
    private struct UX {
        static let cardOuterPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 16
        static let footerTopSpacing: CGFloat = 8
        static let simulatedConnectingDuration: TimeInterval = 2
    }

    @State var theme: Theme
    @State private var isVPNEnabled: Bool
    @State private var isVPNConnecting = false
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let dataUsage: VPNDataUsage
    let onSubSettingTapped: () -> Void
    let onVPNToggled: (Bool) -> Void
    let onLearnMoreTapped: () -> Void

    // a bunch of the closures being passed in are really only used to simulate
    // different scenarios while the backend isn't wired up
    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        isVPNEnabled: Bool = false,
        dataUsage: VPNDataUsage = .placeholder,
        onSubSettingTapped: @escaping () -> Void = {},
        onVPNToggled: @escaping (Bool) -> Void = { _ in },
        onLearnMoreTapped: @escaping () -> Void = {}
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self._isVPNEnabled = State(initialValue: isVPNEnabled)
        self.dataUsage = dataUsage
        self.onSubSettingTapped = onSubSettingTapped
        self.onVPNToggled = onVPNToggled
        self.onLearnMoreTapped = onLearnMoreTapped
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
            VPNSettingsContentView(theme: theme, onLearnMoreTapped: onLearnMoreTapped)
            VPNHelpers.divider()
            VPNLocationsRow(theme: theme, action: onSubSettingTapped)
            VPNHelpers.divider()
            VPNToggleRow(isOn: isVPNEnabled, isConnecting: isVPNConnecting, theme: theme, onChange: handleVPNToggle)
        }
    }

    private var dataUsageSection: some View {
        VStack(alignment: .leading, spacing: UX.footerTopSpacing) {
            VPNHelpers.card(theme: theme) {
                VPNUsageBar(dataUsage: dataUsage, theme: theme)
            }
            Text(String(
                format: .VPN.Settings.DataLimitResetFooter,
                VPNHelpers.formatted(gigabytes: dataUsage.dataLimitInGB)
            ))
                .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.textSecondary.color)
                .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel(Text(String.VPN.Settings.DataLimitTitle))
        .accessibilityValue(VPNHelpers.usageAccessibilityText(
            usedDataInGB: dataUsage.clampedUsedDataInGB,
            dataLimitInGB: dataUsage.dataLimitInGB
        ))
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.dataUsage)
    }

    // MARK: - Actions

    // TODO: Replace this with real VPN connection stuff
    private func handleVPNToggle(_ isOn: Bool) {
        guard isOn else {
            isVPNEnabled = false
            onVPNToggled(false)
            return
        }
        guard !isVPNConnecting else { return }

        isVPNConnecting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.simulatedConnectingDuration) {
            isVPNConnecting = false
            isVPNEnabled = true
            onVPNToggled(true)
            UIAccessibility.post(notification: .announcement, argument: String.VPN.Settings.Connected)
        }
    }
}

// MARK: - Content View

struct VPNSettingsContentView: View {
    private struct UX {
        static let globeViewPadding: CGFloat = 12
        static let globeViewBottomPadding: CGFloat = 16
        static let titleVerticalPadding: CGFloat = 4
        static let descriptionLineHeight: CGFloat = 21
        static let learnMoreBottomPadding: CGFloat = 10
    }

    let theme: Theme
    let onLearnMoreTapped: () -> Void
    @AccessibilityFocusState private var isTitleFocused: Bool

    private var descriptionLineSpacing: CGFloat {
        max(0, UX.descriptionLineHeight - FXFontStyles.Regular.callout.scaledFont().lineHeight)
    }

    var body: some View {
        VStack(alignment: .leading) {
            VPNGlobeView(theme: theme)
                .padding(UX.globeViewPadding)
                .padding(.bottom, UX.globeViewBottomPadding)
            Text(String.VPN.Settings.Title)
                .font(FXFontStyles.Bold.title3.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isTitleFocused)
                .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.heading)
                .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
                .padding(.vertical, UX.titleVerticalPadding)
            Text(String.VPN.Settings.Description)
                .font(FXFontStyles.Regular.callout.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.textSecondary.color)
                .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.description)
                .lineSpacing(descriptionLineSpacing)
                .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
            Button(action: onLearnMoreTapped) {
                Text(String.VPN.Settings.LearnMore)
                    .font(FXFontStyles.Regular.callout.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textAccent.color)
                    .padding(.bottom, UX.learnMoreBottomPadding)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.learnMoreButton)
            .accessibilityRemoveTraits(.isButton)
            .accessibilityAddTraits(.isLink)
            .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
        }
        .onAppear { isTitleFocused = true }
    }
}

// MARK: - Globe Icon

struct VPNGlobeView: View {
    private struct UX {
        static let iconSize: CGFloat = 44
        static let containerSize: CGFloat = 60
        static let containerCornerRadius: CGFloat = 16
    }

    let theme: Theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UX.containerCornerRadius)
                .fill(
                    LinearGradient(gradient: theme.colors.gradientAccentSubtle.swiftUI,
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: UX.containerCornerRadius))

            Image(decorative: StandardImageIdentifiers.Large.globe)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: UX.iconSize, height: UX.iconSize)
                .foregroundStyle(
                    LinearGradient(gradient: theme.colors.gradientAccent.swiftUI,
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
        }
        .frame(width: UX.containerSize, height: UX.containerSize)
        .accessibilityHidden(true)
    }
}

// MARK: - Locations Row

struct VPNLocationsRow: View {
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(String.VPN.Settings.LocationTitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Spacer()
                Text(String.VPN.Settings.LocationRecommended)
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
        .accessibilityValue(String.VPN.Settings.LocationRecommended)
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.locationSetting)
    }
}

// MARK: - VPNToggleRow

struct VPNToggleRow: View {
    let isOn: Bool
    let isConnecting: Bool
    let theme: Theme
    let onChange: (Bool) -> Void

    private var accessibilityValue: String {
        if isConnecting { return .VPN.Settings.Connecting }
        return isOn ? .VPN.Settings.StatusOn : .VPN.Settings.StatusOff
    }

    var body: some View {
        Toggle(isOn: Binding(get: { isOn }, set: { onChange($0) })) {
            HStack {
                Text(String.VPN.Settings.ToggleTitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Spacer()
                if isConnecting {
                    ProgressView()
                        .accessibilityHidden(true)
                    Text(String.VPN.Settings.Connecting)
                        .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                        .foregroundStyle(theme.colors.textSecondary.color)
                        .accessibilityHidden(true)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: theme.colors.actionPrimary.color))
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.vpnToggle)
        .accessibilityValue(accessibilityValue)
        .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
        .padding(.vertical, VPNHelpers.UX.rowVerticalPadding)
    }
}

// MARK: - VPNUsageBar

struct VPNUsageBar: View {
    let dataUsage: VPNDataUsage
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(String.VPN.Settings.DataLimitTitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Spacer()
                Text(VPNHelpers.usageText(
                    usedDataInGB: dataUsage.clampedUsedDataInGB,
                    dataLimitInGB: dataUsage.dataLimitInGB
                ))
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            ProgressView(value: dataUsage.usageFraction)
                .tint(VPNHelpers.progressColor(usageFraction: dataUsage.usageFraction, theme: theme))
        }
        .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
        .padding(.vertical, VPNHelpers.UX.rowVerticalPadding)
    }
}

// MARK: - Data Usage

// TODO: Replace the sample values with real usage data once the VPN backend provides it
struct VPNDataUsage: Equatable {
    static let placeholder = VPNDataUsage(usedDataInGB: 2.3, dataLimitInGB: 5)

    let usedDataInGB: Double
    let dataLimitInGB: Double

    var clampedUsedDataInGB: Double {
        min(usedDataInGB, dataLimitInGB)
    }

    var usageFraction: Double {
        guard dataLimitInGB > 0 else { return 0 }
        return min(usedDataInGB / dataLimitInGB, 1)
    }

    var isLimitReached: Bool {
        usageFraction >= 1
    }
}

// MARK: - Helpers

struct VPNHelpers {
    struct UX {
        static let horizontalPadding: CGFloat = 16
        static let rowVerticalPadding: CGFloat = 12
        static let cardCornerRadius: CGFloat = 26
        static let warningUsageThreshold = 0.75
        static let fullUsageOpacity: CGFloat = 0.75
    }

    // MARK: - Layout

    static func divider() -> some View {
        Divider().padding(.horizontal, UX.horizontalPadding)
    }

    static func card(theme: Theme, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .background(theme.colors.layer2.color)
            .clipShape(RoundedRectangle(cornerRadius: UX.cardCornerRadius))
    }

    // MARK: - Data Usage

    static func progressColor(usageFraction: Double, theme: Theme) -> Color {
        if usageFraction < UX.warningUsageThreshold {
            return theme.colors.faviconLetterColorSet.iconAccentGreen4.color
        } else if usageFraction < 1 {
            return theme.colors.faviconLetterColorSet.iconAccentOrange4.color
        }
        return theme.colors.faviconLetterColorSet.iconAccentRed4.color.opacity(UX.fullUsageOpacity)
    }

    static func usageText(usedDataInGB: Double, dataLimitInGB: Double) -> String {
        String(
            format: .VPN.Settings.DataUsage,
            formatted(gigabytes: usedDataInGB),
            formatted(gigabytes: dataLimitInGB)
        )
    }

    static func usageAccessibilityText(usedDataInGB: Double, dataLimitInGB: Double) -> String {
        String(
            format: .VPN.Settings.DataLimitAccessibilityValue,
            formatted(gigabytes: usedDataInGB),
            formatted(gigabytes: dataLimitInGB)
        )
    }

    /// Formats a data amount to one decimal place, e.g. `5` becomes "5.0".
    static func formatted(gigabytes: Double) -> String {
        gigabytes.formatted(.number.precision(.fractionLength(1)))
    }
}
