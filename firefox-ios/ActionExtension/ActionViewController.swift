// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import Shared
import Storage
import Account
import Common

class ActionViewController: UIViewController {

    var embedController: EmbeddedNavController?
    var shareViewController: ShareViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        view.backgroundColor = .clear
        self.view.alpha = 0

        // Extract the shared item using the same helper as the share extension.
        self.getShareItem { shareItem in
            DispatchQueue.main.async {
                guard let shareItem = shareItem else {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "There was an error processing the shared item.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.finish(afterDelay: 0)
                    })
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                // Instantiate the ShareViewController (which handles all Firefox actions)
                let shareController = ShareViewController()
                shareController.delegate = self
                shareController.shareItem = shareItem
                self.shareViewController = shareController

                // Embed the ShareViewController using the EmbeddedNavController from the share extension
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
        // Fade in the UI to match the share extension’s animation
        UIView.animate(withDuration: 0.2) {
            self.view.alpha = 1
        }
    }

    // Extract shared item similar to the share extension's implementation.
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

    // Called by the ShareViewController when an action is completed.
    func finish(afterDelay: TimeInterval) {
        UIView.animate(withDuration: 0.2, delay: afterDelay, options: [], animations: {
            self.view.alpha = 0
        }, completion: { _ in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
    }
}

extension ActionViewController: ShareControllerDelegate {
    func getValidExtensionContext() -> NSExtensionContext? {
        return self.extensionContext
    }
    
    func hidePopupWhenShowingAlert() {
        // Hide the popup UI, similar to the share extension behavior.
        self.embedController?.navigationController.view.alpha = 0
    }
}
