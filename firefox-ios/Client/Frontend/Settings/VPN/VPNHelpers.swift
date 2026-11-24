// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

enum VPNHelpers {
    enum UX {
        static let horizontalPadding: CGFloat = 16
        static let rowVerticalPadding: CGFloat = 12
        static let cardCornerRadius: CGFloat = 26
        static let loadingSpacing: CGFloat = 8
        static let warningUsageThreshold = 0.75
        static let fullUsageOpacity: CGFloat = 0.75
    }

    // MARK: - Views

    static func divider() -> some View {
        Divider().padding(.horizontal, UX.horizontalPadding)
    }

    static func card(theme: Theme, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .background(theme.colors.layer5.color)
            .clipShape(RoundedRectangle(cornerRadius: UX.cardCornerRadius))
    }

    @MainActor
    static func loadingIndicator(text: String, theme: Theme) -> some View {
        HStack(spacing: UX.loadingSpacing) {
            ProgressView()
                .accessibilityHidden(true)
            Text(text)
                .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.textSecondary.color)
        }
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

    /// Formats a data amount to one decimal place, e.g. 5 becomes 5.0.
    static func formatted(gigabytes: Double) -> String {
        gigabytes.formatted(.number.precision(.fractionLength(1)))
    }
}
