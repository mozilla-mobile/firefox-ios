// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import SwiftUI

@MainActor
protocol WallpaperEngagementCoordinatorDelegate: AnyObject {
    func wallpaperEngagementDidTapCTA(from coordinator: WallpaperEngagementCoordinator)
}

@MainActor
final class WallpaperEngagementCoordinator: BaseCoordinator {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var delegate: WallpaperEngagementCoordinatorDelegate?

    private let windowUUID: WindowUUID
    private let featureFlagsProvider: FeatureFlagProviding
    private let nimbus: FxNimbus
    private let prefs: Prefs
    private let wallpaperManager: WallpaperManagerInterface

    private var marketingSlug: String {
        return nimbus.features.wallpaperEngagementSheetFeature.value().marketingSlug
    }

    private var hasBottomSafeArea: Bool {
        guard let viewController = router.navigationController as? UIViewController else { return false }
        return viewController.view.safeAreaInsets.bottom > 0
    }

    init(
        router: Router,
        windowUUID: WindowUUID,
        prefs: Prefs,
        wallpaperManager: WallpaperManagerInterface = WallpaperManager(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        nimbus: FxNimbus = .shared
    ) {
        self.windowUUID = windowUUID
        self.prefs = prefs
        self.wallpaperManager = wallpaperManager
        self.featureFlagsProvider = featureFlagsProvider
        self.nimbus = nimbus
        super.init(router: router)
    }

    func shouldShow() -> Bool {
        return true
        guard featureFlagsProvider.isEnabled(.wallpaperEngagementSheet),
              !marketingSlug.isEmpty,
              wallpaperManager.canSettingsBeShown
        else { return false }
        // The marketing slug needs to be different then the one saved since we can't programmatically unenroll
        // from the rollout. Also this gives the ability to enable a new rollout with different marketing slug.
        return marketingSlug != prefs.stringForKey(PrefsKeys.Wallpapers.EngagementSheetShownMarketingSlug)
    }

    func start() {
        let contentView = WallpaperEngagementView(
            windowUUID: windowUUID,
            hasBottomSafeArea: hasBottomSafeArea
        ) { [weak self] in
            self?.router.dismiss(animated: true) {
                guard let self else { return }
                self.delegate?.wallpaperEngagementDidTapCTA(from: self)
            }
        }
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.view.backgroundColor = .clear

        let bottomSheetVC = NativeBottomSheetViewController(windowUUID: windowUUID)
        bottomSheetVC.onDismiss = { [weak self] in
            self?.finish()
        }
        bottomSheetVC.configure(
            closeButtonModel: CloseButtonViewModel(
                a11yLabel: .CloseButtonTitle,
                a11yIdentifier: AccessibilityIdentifiers.WallpaperEngagementSheet.closeButton
            ),
            child: hostingController
        )

        router.present(bottomSheetVC, animated: true) { [weak self] in
            self?.finish()
        }
        prefs.setString(marketingSlug, forKey: PrefsKeys.Wallpapers.EngagementSheetShownMarketingSlug)
    }

    private func finish() {
        parentCoordinator?.didFinish(from: self)
    }
}

private struct WallpaperEngagementView: ThemeableView {
    private struct UX {
        static let imageSize: CGFloat = 200
        static let imageTopPadding: CGFloat = 8
        // This is hard coded and not following design system since it is going to be changed
        // according to the new theme of wallpapers released e.g (Christmas).
        static let backdropColor = Color(UIColor(rgb: 0x8E5CD9))
        static let backdropHeight: CGFloat = imageSize / 1.7
        static let backdropOpacityStart: CGFloat = 0.5
        static let backdropOpacityEnd: CGFloat = 0.0
        static let backdropBlurRadius: CGFloat = 10.0
        static let imageTitleSpacing: CGFloat = 0.0
        static let titleSpacing: CGFloat = 8
        static let textsHorizontalPadding: CGFloat = 40.0
        static let contentBottomPadding: CGFloat = 24
        static let horizontalPadding: CGFloat = 24
        static let bottomPadding: CGFloat = 24
        static let contentMaxWidth: CGFloat = 420
        static let buttonMaxWidth: CGFloat = 367
    }

    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    @State var theme: Theme
    private let hasBottomSafeArea: Bool
    private let onTapCTA: () -> Void

    init(
        windowUUID: WindowUUID,
        hasBottomSafeArea: Bool,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        onTapCTA: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.hasBottomSafeArea = hasBottomSafeArea
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
        self.onTapCTA = onTapCTA
    }

    var body: some View {
        VStack(spacing: 0) {
            promo
                .padding(.top, UX.imageTopPadding)
                .padding(.bottom, UX.imageTitleSpacing)
            VStack(spacing: UX.titleSpacing) {
                Text(String.Wallpapers.EngagementSheetTitle)
                    .font(FXFontStyles.Bold.title2.scaledSwiftUIFont())
                    .foregroundColor(theme.colors.textPrimary.color)
                Text(String.Wallpapers.EngagementSheetDescription)
                    .font(FXFontStyles.Regular.callout.scaledSwiftUIFont())
                    .foregroundColor(theme.colors.textSecondary.color)
                    .padding(.horizontal, UX.textsHorizontalPadding)
            }
            .multilineTextAlignment(.center)
            .padding(.bottom, UX.contentBottomPadding)
            Button(action: onTapCTA) {
                Text(String.Wallpapers.EngagementSheetButton)
            }
            .primaryButtonStyle(theme: theme)
            .frame(maxWidth: UX.buttonMaxWidth)
            .accessibilityIdentifier(AccessibilityIdentifiers.WallpaperEngagementSheet.ctaButton)
        }
        .padding(.horizontal, UX.horizontalPadding)
        .frame(maxWidth: UX.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.bottom, hasBottomSafeArea ? 0 : UX.bottomPadding)
        .listenToThemeChanges(in: self, theme: $theme)
    }

    private var promo: some View {
        promoImage
            .frame(width: UX.imageSize, height: UX.imageSize)
            .frame(maxWidth: .infinity)
            .background(alignment: .bottom) {
                backdrop
            }
            .accessibilityHidden(true)
    }

    private var backdrop: some View {
        Ellipse()
            .fill(
                EllipticalGradient(
                    colors: [
                        UX.backdropColor.opacity(UX.backdropOpacityStart),
                        UX.backdropColor.opacity(UX.backdropOpacityEnd)
                    ]
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: UX.backdropHeight)
            .blur(radius: UX.backdropBlurRadius)
            .offset(CGSize(width: 0.0, height: UX.backdropHeight / 5))
    }

    private var promoImage: some View {
        Image(StandardImageIdentifiers.Large.image)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(theme.colors.iconSecondary.color)
    }
}
