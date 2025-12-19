// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that displays account impact information for both logged-in and guest users
@available(iOS 16.0, *)
public struct EcosiaAccountImpactView: View {
    @ObservedObject private var viewModel: EcosiaAccountImpactViewModel
    @ObservedObject private var authStateProvider = EcosiaAuthUIStateProvider.shared
    private let windowUUID: WindowUUID

    @State private var theme = EcosiaAccountImpactViewTheme()
    @State private var showSeedsCounterInfoWebView = false
    @State private var showProfileWebView = false
    @State private var showSparkles = false

    /// Layout configuration optimized for account impact cards
    private var impactCardLayout: NudgeCardLayout {
        NudgeCardLayout(
            imageSize: UX.imageImpactWidthHeight,
            closeButtonSize: UX.closeButtonSize,
            horizontalSpacing: .ecosia.space._m,
            borderWidth: UX.borderWidth
        )
    }

    public init(
        viewModel: EcosiaAccountImpactViewModel,
        windowUUID: WindowUUID
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
    }

    public var body: some View {
        VStack(spacing: .ecosia.space._l) {
            // User info section with avatar (always present)
            HStack(alignment: .center, spacing: .ecosia.space._m) {
                EcosiaAccountProgressAvatar(
                    avatarURL: viewModel.avatarURL,
                    progress: viewModel.levelProgress,
                    showSparkles: showSparkles,
                    showProgress: !authStateProvider.hasRegisterVisitError,
                    windowUUID: windowUUID,
                    onLevelUpAnimationComplete: {
                        showSparkles = false
                    }
                )

                VStack(alignment: .leading, spacing: .ecosia.space._1s) {
                    Text(viewModel.userDisplayText)
                        .font(.ecosia(size: .ecosia.font._2l, weight: .bold))
                        .foregroundColor(theme.textPrimaryColor)
                        .accessibilityIdentifier("account_impact_username")
                        .frame(minHeight: 25)

                    Text(viewModel.levelDisplayText)
                        .font(.ecosia(size: .ecosia.font._s, weight: .medium))
                        .foregroundColor(theme.levelTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.levelBackgroundColor)
                        )
                        .accessibilityLabel(String(format: .localized(.userLevelAccessibilityLabel), viewModel.levelDisplayText))
                        .accessibilityIdentifier("account_impact_level")
                }
            }
            .padding(.horizontal, .ecosia.space._m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            // Show error view if register visit failed
            if authStateProvider.hasRegisterVisitError {
                EcosiaErrorView(
                    title: String.localized(.couldNotLoadSeedCounter),
                    subtitle: String.localized(.couldNotLoadSeedCounterMessage),
                    windowUUID: windowUUID
                )
                .padding(.horizontal, .ecosia.space._m)
            }

            // Conditional content based on login state
            ZStack(alignment: .top) {
                if !viewModel.isLoggedIn {
                    EcosiaAccountSignedOutView(
                        viewModel: viewModel,
                        windowUUID: windowUUID,
                        theme: theme,
                        onLearnMoreTap: {
                            showSeedsCounterInfoWebView = true
                        }
                    )
                    .transition(.opacity)
                    .zIndex(0)
                }

                if viewModel.isLoggedIn {
                    EcosiaAccountSignedInView(
                        viewModel: viewModel,
                        windowUUID: windowUUID,
                        theme: theme,
                        onProfileTap: {
                            showProfileWebView = true
                        },
                        onSignOutTap: {
                            Task {
                                await viewModel.handleLogout()
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoggedIn)
        }
        .ecosiaThemed(windowUUID, $theme)
        .onChange(of: authStateProvider.currentLevelNumber) { _ in
            let themeManager = AppContainer.shared.resolve() as ThemeManager
            theme.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .EcosiaAccountLevelUp)) { _ in
            showSparkles = true
        }
        .sheet(isPresented: $showSeedsCounterInfoWebView) {
            EcosiaWebViewModal(
                url: EcosiaEnvironment.current.urlProvider.seedCounterInfo,
                windowUUID: windowUUID
            )
        }
        .sheet(isPresented: $showProfileWebView) {
            EcosiaWebViewModal(
                url: EcosiaEnvironment.current.urlProvider.profileURL,
                windowUUID: windowUUID,
                onLoadComplete: {
                    Analytics.shared.accountProfileViewed()
                },
                onDismiss: {
                    Analytics.shared.accountProfileDismissed()
                }
            )
        }
    }

    // MARK: - UX Constants
    private enum UX {
        static let closeButtonSize: CGFloat = 15
        static let closeButtonBackgroundSize: CGFloat = 30
        static let imageImpactWidthHeight: CGFloat = 80
        static let borderWidth: CGFloat = 1
    }
}

/// Theme configuration for EcosiaAccountImpactView
@available(iOS 16.0, *)
public struct EcosiaAccountImpactViewTheme: EcosiaThemeable {
    public var backgroundColor = Color.white
    public var cardBackgroundColor = Color.white
    public var textPrimaryColor = Color.black
    public var textSecondaryColor = Color.gray
    public var cardActionButtonTextColor = Color.blue
    public var cardCloseButtonColor = Color.gray.opacity(0.3)
    public var signInButtonBackgroundColor = Color.green
    public var signInButtonTextColor = Color.green
    public var signOutImageTintColor = Color.green
    public var signOutButtonTextColor = Color.green
    public var borderColor = Color.gray.opacity(0.2)
    public var avatarPlaceholderColor = Color.gray.opacity(0.3)
    public var avatarIconColor = Color.gray
    public var levelTextColor = Color.white
    public var levelBackgroundColor = Color.black

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundPrimary)
        cardBackgroundColor = Color(theme.colors.ecosia.backgroundElevation1)
        cardActionButtonTextColor = Color(theme.colors.ecosia.buttonContentSecondary)
        cardCloseButtonColor = Color(theme.colors.ecosia.buttonContentSecondary)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        textSecondaryColor = Color(theme.colors.ecosia.textSecondary)
        signInButtonBackgroundColor = Color(theme.colors.ecosia.buttonBackgroundFeatured)
        signInButtonTextColor = Color(theme.colors.ecosia.buttonContentSecondaryStatic)
        signOutImageTintColor = Color(theme.colors.ecosia.buttonContentSecondary)
        signOutButtonTextColor = Color(theme.colors.ecosia.buttonContentSecondary)
        borderColor = Color(theme.colors.ecosia.borderDecorative)
        avatarPlaceholderColor = Color(theme.colors.ecosia.backgroundTertiary)
        avatarIconColor = Color(theme.colors.ecosia.backgroundPrimary)

        if EcosiaAuthUIStateProvider.shared.currentLevelNumber > 1 {
            levelTextColor = Color(theme.colors.ecosia.textStaticDark)
            levelBackgroundColor = Color(theme.colors.ecosia.brandImpact)
        } else {
            levelTextColor = Color(theme.colors.ecosia.textInversePrimary)
            levelBackgroundColor = Color(theme.colors.ecosia.backgroundNeutralInverse)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaAccountImpactView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Guest user state
            EcosiaAccountImpactView(
                viewModel: EcosiaAccountImpactViewModel(
                    onLogin: {},
                    onDismiss: {}
                ),
                windowUUID: .XCTestDefaultUUID
            )
            .previewDisplayName("Guest User")

            // Logged in user state
            EcosiaAccountImpactView(
                viewModel: EcosiaAccountImpactViewModel(
                    onLogin: {},
                    onDismiss: {}
                ),
                windowUUID: .XCTestDefaultUUID
            )
            .previewDisplayName("Logged In User")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
