// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class WallpaperBaseViewController: UIViewController {
    // Updates the layout when the horizontal or vertical size class changes
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            updateOnRotation()
        }
    }

    // Updates the layout on rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateOnRotation()
    }

    /// On iPhone, we call updateOnRotation when the trait collection has changed, to ensure calculation
    /// is done with the new trait. On iPad, trait collection doesn't change from portrait to landscape (and vice-versa)
    /// since it's `.regular` on both. We updateOnRotation from viewWillTransition in that case.
    func updateOnRotation() {
    }

    func showError(_ error: Error, retryHandler: @escaping (UIAlertAction) -> Void) {
        let alert: UIAlertController

        switch error {
        case WallpaperManagerError.downloadFailed(_):
            alert = UIAlertController(title: .CouldntDownloadWallpaperErrorTitle,
                                      message: .CouldntDownloadWallpaperErrorBody,
                                      preferredStyle: .alert)
        default:
            alert = UIAlertController(title: .CouldntChangeWallpaperErrorTitle,
                                      message: .CouldntChangeWallpaperErrorBody,
                                      preferredStyle: .alert)
        }

        let retryAction = UIAlertAction(title: .WallpaperErrorTryAgain,
                                        style: .default,
                                        handler: retryHandler)
        let dismissAction = UIAlertAction(title: .WallpaperErrorDismiss,
                                          style: .cancel,
                                          handler: nil)
        alert.addAction(retryAction)
        alert.addAction(dismissAction)
        present(alert, animated: true, completion: nil)
    }
}
