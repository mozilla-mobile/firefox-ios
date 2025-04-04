// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage

class ActionViewController: UIViewController, ShareControllerDelegate {
    private var embedController: EmbeddedNavController?
    private var shareViewController: ShareViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        view.backgroundColor = .clear
        view.alpha = 0

        getShareItem { [weak self] shareItem in
            guard let self = self else { return }
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
        UIView.animate(withDuration: 0.2) {
            self.view.alpha = 1
        }
    }

    /// Extracts the shared item using the extension’s helper.
    private func getShareItem(completion: @escaping (ExtensionUtils.ExtractedShareItem?) -> Void) {
        ExtensionUtils.extractSharedItem(fromExtensionContext: extensionContext) { [weak self] item, error in
            if let item = item, error == nil {
                completion(item)
            } else {
                completion(nil)
                self?.extensionContext?.cancelRequest(withError: CocoaError(.keyValueValidation))
            }
        }
    }

    /// Fades out the UI and completes the extension request.
    func finish(afterDelay delay: TimeInterval) {
        UIView.animate(withDuration: 0.2, delay: delay, options: [], animations: {
            self.view.alpha = 0
        }) { _ in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    func getValidExtensionContext() -> NSExtensionContext? {
        extensionContext
    }
    
    /// Hides the popup UI when an alert is presented.
    func hidePopupWhenShowingAlert() {
        embedController?.navigationController.view.alpha = 0
    }
}
