/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Deferred
import Shared
import Storage

// Reports portrait screen size regardless of the current orientation.
func screenSizeOrientationIndependent() -> CGSize {
    let screenSize = UIScreen.main.bounds.size
    return CGSize(width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
}

// Small iPhone screens in landscape require that the popup have a shorter height.
func isLandscapeSmallScreen(_ traitCollection: UITraitCollection) -> Bool {
    let hasSmallScreen = screenSizeOrientationIndependent().width <= CGFloat(UX.topViewWidth)
    return hasSmallScreen && traitCollection.verticalSizeClass == .compact
}

/*
 The initial view controller is full-screen and is the only one with a valid extension context.
 It is just a wrapper with a semi-transparent background to darken the screen
 that embeds the share view controller which is designed to look like a popup.

 The share view controller is embedded using a navigation controller to get a nav bar
 and standard iOS navigation behaviour.
 */

class EmbeddedNavController {
    weak var parent: UIViewController?
    var controllers = [UIViewController]()
    var navigationController: UINavigationController
    var heightConstraint: Constraint!

    init(parent: UIViewController, rootViewController: UIViewController) {
        self.parent = parent
        navigationController = UINavigationController(rootViewController: rootViewController)

        parent.addChildViewController(navigationController)
        parent.view.addSubview(navigationController.view)

        let width = min(screenSizeOrientationIndependent().width * 0.90, CGFloat(UX.topViewWidth))

        navigationController.view.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(width)
            heightConstraint = make.height.equalTo(UX.topViewHeight).constraint
            if isLandscapeSmallScreen(navigationController.traitCollection) {
                layout(forTraitCollection: navigationController.traitCollection)
            }
        }

        navigationController.view.layer.cornerRadius = UX.dialogCornerRadius
        navigationController.view.layer.masksToBounds = true
    }

    func layout(forTraitCollection: UITraitCollection) {
        if isLandscapeSmallScreen(forTraitCollection) {
            heightConstraint.update(offset: UX.topViewHeight - (UX.numberOfActionRows + 2) * UX.perRowShrinkageForLandscape)
        } else {
            heightConstraint.update(offset: UX.topViewHeight)
        }
    }

    deinit {
        navigationController.view.removeFromSuperview()
        navigationController.removeFromParentViewController()
    }
}

@objc(InitialViewController)
class InitialViewController: UIViewController {
    var embedController: EmbeddedNavController!
    var shareViewController: ShareViewController!

    override func viewDidLoad() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.0, alpha: UX.alphaForFullscreenOverlay)
        // This is the view controller for the popup dialog
        shareViewController = ShareViewController()
        shareViewController.delegate = self
        embedController = EmbeddedNavController(parent: self, rootViewController: shareViewController)
        view.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // The system share dialog dims the screen, then once our share action is selected it closes and the
        // screen undims and our view controller is shown which again dims the screen. Without a short fade in
        // the effect appears flash-like.
        UIView.animate(withDuration: 0.2) {
            self.view.alpha = 1
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        setOverrideTraitCollection(UITraitCollection(verticalSizeClass: .compact), forChildViewController: embedController.navigationController)
        coordinator.animate(alongsideTransition: { _ in
            self.embedController.layout(forTraitCollection: newCollection)
            self.shareViewController.layout(forTraitCollection: newCollection)
        }) { _ in
            // There is a layout change propagation bug for this view setup (i.e. container view controller that is a UINavigationViewController).
            // This is the only way to force UINavigationBar to perform a layout. Without this, the layout is for the previous size class.
            self.embedController.navigationController.isNavigationBarHidden = true
            self.embedController.navigationController.isNavigationBarHidden = false
        }
    }
}

extension InitialViewController: ShareControllerDelegate {
    func finish(afterDelay: TimeInterval) {
        UIView.animate(withDuration: 0.2, delay: afterDelay, options: [], animations: {
            self.view.alpha = 0
        }, completion: { _ in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
    }

    func getValidExtensionContext() -> NSExtensionContext? {
        return extensionContext
    }

    func getShareItem() -> Deferred<ShareItem?> {
        let deferred = Deferred<ShareItem?>()
        ExtensionUtils.extractSharedItemFromExtensionContext(extensionContext, completionHandler: { item, error in
            if let item = item, error == nil {
                deferred.fill(item)
            } else {
                deferred.fill(nil)
                self.extensionContext?.cancelRequest(withError: CocoaError(.keyValueValidation))
            }
        })

        return deferred
    }

    // At startup, the extension may show an alert that it can't share. In this case for a better UI, rather than showing
    // 2 popup dialogs (the main one and then the alert), just show the alert.
    func hidePopupWhenShowingAlert() {
        embedController.navigationController.view.alpha = 0
    }
}
