// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Storage

// Small iPhone screens in landscape require that the popup have a shorter height.
func isLandscapeSmallScreen(_ traitCollection: UITraitCollection) -> Bool {
    if !UX.enableResizeRowsForSmallScreens {
        return false
    }

    let hasSmallScreen = DeviceInfo.screenSizeOrientationIndependent().width <= CGFloat(UX.topViewWidth)
    return hasSmallScreen && traitCollection.verticalSizeClass == .compact
}

/*
 The initial view controller is full-screen and is the only one with a valid extension context.
 It is just a wrapper with a semi-transparent background to darken the screen
 that embeds the share view controller which is designed to look like a popup.

 The share view controller is embedded using a navigation controller to get a nav bar
 and standard iOS navigation behaviour.
 */

@objc(InitialViewController)
class InitialViewController: UIViewController {
    var embedController: EmbeddedNavController?
    var shareViewController: ShareViewController?

    override func viewDidLoad() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        super.viewDidLoad()

        view.backgroundColor = .clear

        // iPad drop shadow removal hack!
        var view = parent?.view
        while view != nil, view!.classForCoder.description() != "UITransitionView" {
            view = view?.superview
        }
        if let view = view {
            // For reasons unknown, if the alpha is < 1.0, the drop shadow is not shown
            view.alpha = 0.99
        }

        self.view.alpha = 0

        self.getShareItem { shareItem in
            DispatchQueue.main.async {
                guard let shareItem = shareItem else {
                    let alert = UIAlertController(
                        title: .SendToErrorTitle,
                        message: .SendToErrorMessage,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(
                        title: .SendToErrorOKButton,
                        style: .default
                    ) { _ in self.finish(afterDelay: 0)
                    })
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                // This is the view controller for the popup dialog
                let shareController = ShareViewController()
                shareController.delegate = self
                shareController.shareItem = shareItem
                self.shareViewController = shareController

                self.embedController = EmbeddedNavController(
                    isSearchMode: !shareItem.isUrlType(),
                    parent: self,
                    rootViewController: shareController
                )
            }
        }
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

    func getShareItem(completion: @escaping (ExtensionUtils.ExtractedShareItem?) -> Void) {
        ExtensionUtils.extractSharedItem(fromExtensionContext: extensionContext) { item, error in
            if let item = item, error == nil {
                completion(item)
            } else {
                completion(nil)
                self.extensionContext?.cancelRequest(withError: CocoaError(.keyValueValidation))
            }
        }
    }

    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        guard let embedController = embedController, let shareViewController = shareViewController else { return }
        coordinator.animate(alongsideTransition: { _ in
            embedController.layout(forTraitCollection: newCollection)
            shareViewController.layout(forTraitCollection: newCollection)
        }) { _ in
            // There is a layout change propagation bug for this view setup (i.e. container view controller
            // that is a UINavigationViewController). This is the only way to force UINavigationBar
            // to perform a layout. Without this, the layout is for the previous size class.
            embedController.navigationController.isNavigationBarHidden = true
            embedController.navigationController.isNavigationBarHidden = false
        }
    }
}

extension InitialViewController: ShareControllerDelegate {
    func finish(afterDelay: TimeInterval) {
        UIView.animate(
            withDuration: 0.2,
            delay: afterDelay,
            options: [],
            animations: {
                self.view.alpha = 0
            }, completion: { _ in
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            })
    }

    func getValidExtensionContext() -> NSExtensionContext? {
        return extensionContext
    }

    // At startup, the extension may show an alert that it can't share. In this case for a better UI,
    // rather than showing 2 popup dialogs (the main one and then the alert), just show the alert.
    func hidePopupWhenShowingAlert() {
        embedController?.navigationController.view.alpha = 0
    }
}
