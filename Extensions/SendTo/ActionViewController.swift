/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import SnapKit

/// The ActionViewController is the initial viewcontroller that is presented (full screen) when the share extension
/// is activated. Depending on whether the user is logged in or not, this viewcontroller will present either the
/// InstructionsVC or the ClientPicker VC.

@objc(ActionViewController)
class ActionViewController: UIViewController, ClientPickerViewControllerDelegate, InstructionsViewControllerDelegate {
    private var sharedItem: ShareItem?

    override func viewDidLoad() {
        view.backgroundColor = UIColor.white

        super.viewDidLoad()

        if !hasAccount() {
            let instructionsViewController = InstructionsViewController()
            instructionsViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: instructionsViewController)
            present(navigationController, animated: false, completion: nil)
            return
        }

        ExtensionUtils.extractSharedItemFromExtensionContext(self.extensionContext, completionHandler: { (item, error) -> Void in
            guard let item = item, error == nil, item.isShareable else {
                let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .default) { _ in self.finish() })
                self.present(alert, animated: true, completion: nil)
                return
            }

            self.sharedItem = item
            let clientPickerViewController = ClientPickerViewController()
            clientPickerViewController.clientPickerDelegate = self
            clientPickerViewController.profile = nil // This means the picker will open and close the default profile
            let navigationController = UINavigationController(rootViewController: clientPickerViewController)
            self.present(navigationController, animated: false, completion: nil)
        })
    }

    func finish() {
        self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }

    func clientPickerViewController(_ clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient]) {
        guard let item = sharedItem else {
            return finish()
        }

        let profile = BrowserProfile(localName: "profile", app: nil)
        profile.sendItems([item], toClients: clients).uponQueue(DispatchQueue.main) { result in
            profile.shutdown()
            self.finish()
        }
    }

    func clientPickerViewControllerDidCancel(_ clientPickerViewController: ClientPickerViewController) {
        finish()
    }

    func instructionsViewControllerDidClose(_ instructionsViewController: InstructionsViewController) {
        finish()
    }

    private func hasAccount() -> Bool {
        let profile = BrowserProfile(localName: "profile", app: nil)
        defer {
            profile.shutdown()
        }
        return profile.hasAccount()
    }
}
