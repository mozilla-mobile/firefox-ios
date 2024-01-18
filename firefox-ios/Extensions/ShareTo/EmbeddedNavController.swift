// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Storage

class EmbeddedNavController {
    weak var parent: UIViewController?
    var controllers = [UIViewController]()
    var navigationController: UINavigationController
    var heightConstraint: NSLayoutConstraint!
    let isSearchMode: Bool

    init(isSearchMode: Bool, parent: UIViewController, rootViewController: UIViewController) {
        self.parent = parent
        self.isSearchMode = isSearchMode
        navigationController = UINavigationController(rootViewController: rootViewController)

        parent.addChild(navigationController)
        parent.view.addSubview(navigationController.view)

        let width = min(DeviceInfo.screenSizeOrientationIndependent().width * 0.90, CGFloat(UX.topViewWidth))

        let initialHeight = isSearchMode ? UX.topViewHeightForSearchMode : UX.topViewHeight

        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationController.view.centerXAnchor.constraint(equalTo: parent.view.centerXAnchor),
            navigationController.view.centerYAnchor.constraint(equalTo: parent.view.centerYAnchor),
            navigationController.view.widthAnchor.constraint(equalToConstant: width),
            navigationController.view.heightAnchor.constraint(equalToConstant: CGFloat(initialHeight))
        ])

        heightConstraint = navigationController.view.heightAnchor.constraint(equalToConstant: CGFloat(initialHeight))
        heightConstraint.isActive = true

        navigationController.view.layer.cornerRadius = UX.dialogCornerRadius
        navigationController.view.layer.masksToBounds = true

        layout(forTraitCollection: navigationController.traitCollection)
    }

    func layout(forTraitCollection: UITraitCollection) {
        if isSearchMode {
            // Dialog size doesn't change
            return
        }

        let updatedHeight: CGFloat
        if UX.enableResizeRowsForSmallScreens {
            // Account for one info row
            let shrinkage = UX.navBarLandscapeShrinkage + (UX.numberOfActionRows + 1) * UX.perRowShrinkageForLandscape
            updatedHeight = CGFloat(
                isLandscapeSmallScreen(forTraitCollection) ? UX.topViewHeight - shrinkage : UX.topViewHeight
            )
        } else {
            let compactSize = UX.topViewHeight - UX.navBarLandscapeShrinkage
            updatedHeight = CGFloat(
                forTraitCollection.verticalSizeClass == .compact ? compactSize : UX.topViewHeight
            )
        }

        // Deactivate the existing height constraint
        heightConstraint.isActive = false

        // Create a new height constraint with the updated constant
        heightConstraint = navigationController.view.heightAnchor.constraint(equalToConstant: updatedHeight)
        heightConstraint.isActive = true
    }

    deinit {
        navigationController.view.removeFromSuperview()
        navigationController.removeFromParent()
    }
}
