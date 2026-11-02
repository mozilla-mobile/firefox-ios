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

    private var backdropColor: UIColor {
        let hex = nimbus.features.wallpaperEngagementSheetFeature.value().backdropColor
        return UIColor(colorString: hex.replacingOccurrences(of: "#", with: ""))
    }

    private var image: UIImage? {
        let base64 = nimbus.features.wallpaperEngagementSheetFeature.value().image
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters).flatMap(UIImage.init(data:))
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
        return marketingSlug != prefs.stringForKey(PrefsKeys.Wallpapers.EngagementSheetShownMarketingSlug)
    }

    func start() {
        let contentView = WallpaperEngagementView(
            windowUUID: windowUUID,
            image: image,
            backdropColor: backdropColor
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
                a11yLabel: "Close",
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
    }

    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    @State var theme: Theme
    private let image: UIImage?
    private let backdropColor: UIColor
    @State private var hasBottomSafeArea = false
    private let onTapCTA: () -> Void

    init(
        windowUUID: WindowUUID,
        image: UIImage?,
        backdropColor: UIColor,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        onTapCTA: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.image = image
        self.backdropColor = backdropColor
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
                    Text("A little fright. A fresh look.")
                        .font(FXFontStyles.Bold.title2.scaledSwiftUIFont())
                        .foregroundColor(theme.colors.textPrimary.color)
                    Text("Get into the Halloween spirit with our new wallpapers.")
                        .font(FXFontStyles.Regular.callout.scaledSwiftUIFont())
                        .foregroundColor(theme.colors.textSecondary.color)
                        .padding(.horizontal, UX.textsHorizontalPadding)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, UX.contentBottomPadding)
                Button(action: onTapCTA) {
                    Text("Get Wallpapers")
                }
                .primaryButtonStyle(theme: theme)
                .accessibilityIdentifier(AccessibilityIdentifiers.WallpaperEngagementSheet.ctaButton)
            }
            .padding(.horizontal, UX.horizontalPadding)
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
                        Color(backdropColor).opacity(UX.backdropOpacityStart),
                        Color(backdropColor).opacity(UX.backdropOpacityEnd)
                    ]
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: UX.backdropHeight)
            .blur(radius: UX.backdropBlurRadius)
            .offset(CGSize(width: 0.0, height: UX.backdropHeight / 5))
    }

    @ViewBuilder
    private var promoImage: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(StandardImageIdentifiers.Large.image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(theme.colors.iconSecondary.color)
        }
    }
}
