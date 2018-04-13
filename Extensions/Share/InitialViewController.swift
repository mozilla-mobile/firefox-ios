/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Deferred
import Shared
import Storage

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

    init (parent: UIViewController, rootViewController: UIViewController) {
        self.parent = parent
        navigationController = UINavigationController(rootViewController: rootViewController)

        parent.addChildViewController(navigationController)
        parent.view.addSubview(navigationController.view)

        let width = min(UIScreen.main.bounds.width, CGFloat(UX.topViewWidth))

        navigationController.view.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(UX.topViewHeight)
        }

        navigationController.view.layer.cornerRadius = UX.dialogCornerRadius
        navigationController.view.layer.masksToBounds = true
    }

    deinit {
        navigationController.view.removeFromSuperview()
        navigationController.removeFromParentViewController()
    }
}

@objc(InitialViewController)
class InitialViewController: UIViewController {
    var embedController: EmbeddedNavController!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.0, alpha: UX.alphaForFullscreenOverlay)
        let popupView = ShareViewController()
        popupView.delegate = self
        embedController = EmbeddedNavController(parent: self, rootViewController: popupView)
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
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        })

        return deferred
    }
}
