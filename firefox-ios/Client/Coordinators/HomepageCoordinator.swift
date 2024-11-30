// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared

protocol HomepageDelegate: AnyObject {
     func showWallpaperSelectionOnboarding(_ canPresentModally: Bool)
}

class HomepageCoordinator: BaseCoordinator, HomepageDelegate {
    private let windowUUID: WindowUUID
    private let profile: Profile
    private let wallpaperManager: WallpaperManagerInterface
    private let isZeroSearch: Bool

    init(
        windowUUID: WindowUUID,
        profile: Profile,
        wallpaperManager: WallpaperManagerInterface = WallpaperManager(),
        isZeroSearch: Bool,
        router: Router
    ) {
        self.windowUUID = windowUUID
        self.profile = profile
        self.wallpaperManager = wallpaperManager
        self.isZeroSearch = isZeroSearch
        super.init(router: router)
        self.router = router
    }

    func showWallpaperSelectionOnboarding(_ canPresentModally: Bool) {
        guard canPresentModally,
              isZeroSearch,
              !router.isPresenting,
              wallpaperManager.canOnboardingBeShown(using: profile)
        else { return }

        let viewModel = WallpaperSelectorViewModel(wallpaperManager: wallpaperManager)
        let viewController = WallpaperSelectorViewController(viewModel: viewModel, windowUUID: windowUUID)
        var bottomSheetViewModel = BottomSheetViewModel(
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.closeButton
        )
        bottomSheetViewModel.shouldDismissForTapOutside = false
        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: viewController,
            windowUUID: windowUUID
        )

        router.present(bottomSheetVC, animated: false, completion: nil)
        wallpaperManager.onboardingSeen()
    }
}
