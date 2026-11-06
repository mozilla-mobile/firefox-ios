// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

@available(iOS 17.0, *)
struct VPNSettingsContentView: View {
    private enum UX {
        static let globeViewPadding: CGFloat = 16
        static let titleVerticalPadding: CGFloat = 4
        static let descriptionLineHeight: CGFloat = 21
        static let learnMoreBottomPadding: CGFloat = 10
    }

    let theme: Theme
    // needed only for the Learn More button navigation
    weak var viewController: VPNSettingsViewController?
    @AccessibilityFocusState private var isTitleFocused: Bool

    private var descriptionLineSpacing: CGFloat {
        max(0, UX.descriptionLineHeight - FXFontStyles.Regular.callout.scaledFont().lineHeight)
    }

    var body: some View {
        VStack(alignment: .leading) {
            VPNGlobeView(theme: theme)
                .padding(UX.globeViewPadding)
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
            Button {
                viewController?.learnMoreTapped()
            } label: {
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
