// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that displays the signed-out state of the account impact view
@available(iOS 16.0, *)
public struct EcosiaAccountSignedOutView: View {
    @ObservedObject private var viewModel: EcosiaAccountImpactViewModel
    private let windowUUID: WindowUUID
    private let onLearnMoreTap: () -> Void
    @State private var theme = EcosiaAccountSignedOutViewTheme()
    @State private var isCardDismissed: Bool
    @State private var cardHeight: CGFloat?
    @State private var opacity: Double = 1
    @StateObject private var nudgeCardDelegate = NudgeCardActionHandler()

    /// Layout configuration optimized for account impact cards
    private var impactCardLayout: NudgeCardLayout {
        NudgeCardLayout(
            imageSize: UX.imageImpactWidthHeight,
            closeButtonSize: UX.closeButtonSize,
            closeButtonPaddingTop: .ecosia.space._s,
            closeButtonPaddingLeading: .ecosia.space._s,
            closeButtonPaddingBottom: .ecosia.space._s,
            closeButtonPaddingTrailing: .ecosia.space._s,
            horizontalSpacing: .ecosia.space._m,
            borderWidth: UX.borderWidth
        )
    }

    public init(
        viewModel: EcosiaAccountImpactViewModel,
        windowUUID: WindowUUID,
        theme: EcosiaAccountImpactViewTheme? = nil,
        onLearnMoreTap: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.onLearnMoreTap = onLearnMoreTap
        self._isCardDismissed = State(initialValue: !User.shared.shouldShowAccountImpactNudgeCard)

        if let theme = theme {
            self._theme = State(initialValue: EcosiaAccountSignedOutViewTheme(from: theme))
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._l) {
            // Impact card - with height animation to make sure the dismissal is as smooth as possible
            ConfigurableNudgeCardView(
                viewModel: NudgeCardViewModel(
                    title: String.localized(.seedsSymbolizeYourOwnImpact),
                    description: String.localized(.collectSeedsEveryDayYouUse),
                    buttonText: String.localized(.learnMoreAboutSeeds),
                    image: UIImage(named: "account-menu-impact-flag", in: .ecosia, with: nil),
                    showsCloseButton: true,
                    style: NudgeCardStyle(
                        backgroundColor: theme.cardBackgroundColor,
                        textPrimaryColor: theme.cardTextPrimaryColor,
                        textSecondaryColor: theme.cardTextSecondaryColor,
                        closeButtonTextColor: theme.cardCloseButtonColor,
                        actionButtonTextColor: theme.cardActionButtonTextColor
                    ),
                    layout: impactCardLayout
                ),
                delegate: nudgeCardDelegate
            )
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: CardHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            )
            .onPreferenceChange(CardHeightPreferenceKey.self) { height in
                if cardHeight == nil && height > 0 {
                    cardHeight = height
                }
            }
            .frame(height: isCardDismissed ? 0 : cardHeight)
            .opacity(isCardDismissed ? 0 : 1)
            .clipped()
            .opacity(opacity)

            // Sign Up CTA button
            Button(action: viewModel.handleMainCTATap) {
                Text(viewModel.mainCTAText)
                    .font(.subheadline)
                    .padding(.ecosia.space._m)
                    .frame(maxWidth: .infinity)
                    .frame(height: UX.ctaButtonHeight)
                    .cornerRadius(.ecosia.borderRadius._m)
                    .background(theme.ctaButtonBackgroundColor)
                    .foregroundColor(theme.ctaButtonTextColor)
            }
            .clipShape(Capsule())
            .accessibilityIdentifier("account_impact_cta_button")
            .accessibilityLabel(viewModel.mainCTAText)
            .accessibilityAddTraits(.isButton)
        }
        .ecosiaThemed(windowUUID, $theme)
        .onAppear {
            nudgeCardDelegate.onActionTap = {
                viewModel.handleLearnMoreTap()
                onLearnMoreTap()
            }
            nudgeCardDelegate.onDismissTap = {
                User.shared.hideAccountImpactNudgeCard()
                Analytics.shared.accountImpactCardDismissClicked()
                isCardDismissed = true
            }
        }
    }

    // MARK: - UX Constants
    private enum UX {
        static let closeButtonSize: CGFloat = 15
        static let imageImpactWidthHeight: CGFloat = 80
        static let borderWidth: CGFloat = 1
        static let ctaButtonHeight: CGFloat = 40
    }
}

/// Theme configuration for EcosiaAccountSignedOutView
@available(iOS 16.0, *)
public struct EcosiaAccountSignedOutViewTheme: EcosiaThemeable {
    public var cardBackgroundColor = Color.white
    public var cardTextPrimaryColor = Color.black
    public var cardTextSecondaryColor = Color.gray
    public var cardCloseButtonColor = Color.black
    public var cardActionButtonTextColor = Color.blue
    public var ctaButtonTextColor = Color.green
    public var ctaButtonBackgroundColor = Color.green

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        cardBackgroundColor = Color(theme.colors.ecosia.backgroundElevation1)
        cardTextPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        cardTextSecondaryColor = Color(theme.colors.ecosia.textSecondary)
        cardActionButtonTextColor = Color(theme.colors.ecosia.buttonContentSecondary)
        cardCloseButtonColor = Color(theme.colors.ecosia.buttonContentSecondary)
        ctaButtonTextColor = Color(theme.colors.ecosia.buttonContentSecondaryStatic)
        ctaButtonBackgroundColor = Color(theme.colors.ecosia.buttonBackgroundFeatured)
    }
}

@available(iOS 16.0, *)
extension EcosiaAccountSignedOutViewTheme {

    public init(from parentTheme: EcosiaAccountImpactViewTheme) {
        self.cardBackgroundColor = parentTheme.cardBackgroundColor
        self.cardTextPrimaryColor = parentTheme.textPrimaryColor
        self.cardTextSecondaryColor = parentTheme.textSecondaryColor
        self.cardCloseButtonColor = parentTheme.cardCloseButtonColor
        self.cardActionButtonTextColor = parentTheme.cardActionButtonTextColor
        self.ctaButtonTextColor = parentTheme.signInButtonTextColor
        self.ctaButtonBackgroundColor = parentTheme.signInButtonBackgroundColor
    }
}

// MARK: - Card Height Preference Key

@available(iOS 16.0, *)
private struct CardHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Nudge Card Action Handler

@available(iOS 16.0, *)
private class NudgeCardActionHandler: ObservableObject, ConfigurableNudgeCardActionDelegate {
    var onActionTap: (() -> Void)?
    var onDismissTap: (() -> Void)?

    func nudgeCardRequestToPerformAction() {
        onActionTap?()
    }

    func nudgeCardRequestToDimiss() {
        onDismissTap?()
    }

    func nudgeCardTapped() {
        onActionTap?()
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaAccountSignedOutView_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaAccountSignedOutView(
            viewModel: EcosiaAccountImpactViewModel(
                onLogin: {},
                onDismiss: {}
            ),
            windowUUID: .XCTestDefaultUUID,
            onLearnMoreTap: { print("Learn more tapped") }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
