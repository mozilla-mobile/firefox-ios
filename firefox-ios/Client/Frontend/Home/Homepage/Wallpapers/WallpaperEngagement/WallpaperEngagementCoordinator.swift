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
    private let tabManager: TabManager
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
        tabManager: TabManager,
        prefs: Prefs,
        wallpaperManager: WallpaperManagerInterface = WallpaperManager(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        nimbus: FxNimbus = .shared
    ) {
        self.windowUUID = windowUUID
        self.tabManager = tabManager
        self.prefs = prefs
        self.wallpaperManager = wallpaperManager
        self.featureFlagsProvider = featureFlagsProvider
        self.nimbus = nimbus
        super.init(router: router)
    }

    func shouldShow() -> Bool {
        guard let selectedTab = tabManager.selectedTab,
              selectedTab.isFxHomeTab,
              !selectedTab.isPrivate,
              featureFlagsProvider.isEnabled(.wallpaperEngagementSheet),
              !marketingSlug.isEmpty,
              wallpaperManager.canSettingsBeShown
        else { return false }
        // The marketing slug needs to be different from the saved one, since we can't programmatically unenroll
        // from the rollout. This also lets us enable a new rollout with a different marketing slug.
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
    private enum UX {
        static let imageSize = CGSize(width: 240, height: 200)
        static let imageTopPadding: CGFloat = 8
        // This is hardcoded and doesn't follow the design system, since it will change
        // according to the theme of each new wallpaper release (e.g. Christmas).
        static let backdropColor = Color(UIColor(rgb: 0x6B1E87))
        static let backdropWidth: CGFloat = 340
        static let backdropHeight: CGFloat = 100
        static let backdropVerticalOffset: CGFloat = 100
        static let backdropOpacity = 0.3
        static let backdropBlurRadius: CGFloat = 37
        static let imageTitleSpacing: CGFloat = 8.0
        static let contentBottomPadding: CGFloat = 24
        static let horizontalPadding: CGFloat = 24
        static let bottomPadding: CGFloat = 24
        static let contentMaxWidth: CGFloat = 420
        static let buttonMaxWidth: CGFloat = 367
        static let buttonHorizontalPadding: CGFloat = 40.0
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
            Text(String(format: String.Wallpapers.EngagementSheetTitle, AppName.shortName.rawValue))
                .font(FXFontStyles.Bold.title2.scaledSwiftUIFont())
                .foregroundColor(theme.colors.textPrimary.color)
                .multilineTextAlignment(.center)
                .padding(.bottom, UX.contentBottomPadding)
            Button(action: onTapCTA) {
                Text(String.Wallpapers.EngagementSheetButton)
            }
            .primaryButtonStyle(theme: theme)
            .frame(maxWidth: UX.buttonMaxWidth)
            .padding(.horizontal, UX.buttonHorizontalPadding)
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
            .frame(width: UX.imageSize.width, height: UX.imageSize.height)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                backdrop
                    .offset(.init(width: 0, height: UX.backdropVerticalOffset))
            }
            .accessibilityHidden(true)
    }

    private var backdrop: some View {
        Ellipse()
            .fill(UX.backdropColor)
            .frame(maxWidth: UX.backdropWidth)
            .frame(height: UX.backdropHeight)
            .blur(radius: UX.backdropBlurRadius)
            .opacity(UX.backdropOpacity)
    }

    private var promoImage: some View {
        // This image is going to change for each engagement run, and it will be embedded
        // accordingly.
        Image(ImageIdentifiers.wallpaperEngagement)
            .resizable()
            .scaledToFill()
    }
}
