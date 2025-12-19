// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that displays the signed-in state of the account impact view
@available(iOS 16.0, *)
public struct EcosiaAccountSignedInView: View {
    @ObservedObject private var viewModel: EcosiaAccountImpactViewModel
    @State private var theme = EcosiaAccountSignedInViewTheme()
    private let windowUUID: WindowUUID
    private let onProfileTap: () -> Void
    private let onSignOutTap: () -> Void

    public init(
        viewModel: EcosiaAccountImpactViewModel,
        windowUUID: WindowUUID,
        theme: EcosiaAccountImpactViewTheme? = nil,
        onProfileTap: @escaping () -> Void,
        onSignOutTap: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.onProfileTap = onProfileTap
        self.onSignOutTap = onSignOutTap

        if let theme = theme {
            self._theme = State(initialValue: EcosiaAccountSignedInViewTheme(from: theme))
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._m) {
            VStack(alignment: .leading, spacing: 0) {
                // "Your Ecosia" section title
                ZStack {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: UX.yourEcosiaSectionHeight)
                    Text(String.localized(.yourEcosia))
                        .font(.footnote)
                        .foregroundColor(theme.yourEcosiaTextColor)
                        .padding(.leading, .ecosia.space._s)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("account_signed_in_title")
                }
                // "Your profile" section title
                Button(action: {
                    Analytics.shared.accountProfileClicked()
                    onProfileTap()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                            .fill(theme.yourProfileBackground)
                            .frame(height: UX.yourProfileButtonHeight)
                        Text(String.localized(.yourProfile))
                                .font(.subheadline)
                                .foregroundColor(theme.yourProfileTextColor)
                                .padding(.leading, .ecosia.space._s)
                                .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .accessibilityIdentifier("account_profile_button")
                .accessibilityLabel(String.localized(.yourProfile))
                .accessibilityHint(String.localized(.profileButtonAccessibilityHint))
                .accessibilityAddTraits(.isButton)
            }

            // Sign Out button
            Button(action: {
                Analytics.shared.accountSignOutClicked()
                onSignOutTap()
            }) {
                HStack(alignment: .center, spacing: .ecosia.space._2s) {
                    Image("sign-out", bundle: .ecosia)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: UX.ctaImageSize, height: UX.ctaImageSize)
                        .foregroundColor(theme.ctaButtonImageTintColor)

                    Text(String.localized(.signOut))
                        .font(.subheadline)
                        .foregroundColor(theme.ctaButtonTextColor)
                        .frame(height: UX.ctaButtonHeight)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("account_sign_out_button")
            .accessibilityLabel(String.localized(.signOut))
            .accessibilityHint(String.localized(.signOutButtonAccessibilityHint))
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, .ecosia.space._m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecosiaThemed(windowUUID, $theme)
    }

    // MARK: - UX Constants
    private enum UX {
        static let ctaImageSize: CGFloat = 16
        static let yourEcosiaSectionHeight: CGFloat = 40
        static let yourProfileButtonHeight: CGFloat = 40
        static let ctaButtonHeight: CGFloat = 40
    }
}

/// Theme configuration for EcosiaAccountSignedInView
@available(iOS 16.0, *)
public struct EcosiaAccountSignedInViewTheme: EcosiaThemeable {
    public var yourProfileTextColor = Color.black
    public var yourEcosiaTextColor = Color.gray
    public var yourProfileBackground = Color.white
    public var ctaButtonTextColor = Color.blue
    public var ctaButtonImageTintColor = Color.blue

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        yourProfileTextColor = Color(theme.colors.ecosia.textPrimary)
        yourEcosiaTextColor = Color(theme.colors.ecosia.textSecondary)
        yourProfileBackground = Color(theme.colors.ecosia.backgroundElevation1)
        ctaButtonTextColor = Color(theme.colors.ecosia.buttonContentSecondary)
        ctaButtonImageTintColor = Color(theme.colors.ecosia.buttonContentSecondary)
    }
}

@available(iOS 16.0, *)
extension EcosiaAccountSignedInViewTheme {

    public init(from parentTheme: EcosiaAccountImpactViewTheme) {
        self.yourProfileTextColor = parentTheme.textPrimaryColor
        self.yourEcosiaTextColor = parentTheme.textSecondaryColor
        self.yourProfileBackground = parentTheme.cardBackgroundColor
        self.ctaButtonTextColor = parentTheme.cardActionButtonTextColor
        self.ctaButtonImageTintColor = parentTheme.cardActionButtonTextColor
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaAccountSignedInView_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaAccountSignedInView(
            viewModel: EcosiaAccountImpactViewModel(
                onLogin: {},
                onDismiss: {}
            ),
            windowUUID: .XCTestDefaultUUID,
            onProfileTap: { print("Profile tapped") },
            onSignOutTap: { print("Sign out tapped") }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
