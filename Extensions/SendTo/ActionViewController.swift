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
class ActionViewController: UIViewController, ClientPickerViewControllerDelegate, InstructionsViewControllerDelegate
{
    private lazy var profile: Profile = { return BrowserProfile(localName: "profile", app: nil) }()
    private var sharedItem: ShareItem?

    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()

        super.viewDidLoad()

        guard profile.hasAccount() else {
            let instructionsViewController = InstructionsViewController()
            instructionsViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: instructionsViewController)
            presentViewController(navigationController, animated: false, completion: nil)
            return
        }

        ExtensionUtils.extractSharedItemFromExtensionContext(self.extensionContext, completionHandler: { (item, error) -> Void in
            guard let item = item where error == nil && item.isShareable else {
                let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .Default) { _ in self.finish() })
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }

            let clientPickerViewController = ClientPickerViewController()
            clientPickerViewController.clientPickerDelegate = self
            clientPickerViewController.profile = self.profile
            let navigationController = UINavigationController(rootViewController: clientPickerViewController)
            self.presentViewController(navigationController, animated: false, completion: nil)
        })
    }

    func finish() {
        self.extensionContext!.completeRequestReturningItems(nil, completionHandler: nil)
    }

    func clientPickerViewController(clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient]) {
        // TODO: hook up Send Tab via Sync.
        // profile?.clients.sendItem(self.sharedItem!, toClients: clients)
        if let item = sharedItem {
            self.profile.sendItems([item], toClients: clients)
        }
        finish()
    }
    
    func clientPickerViewControllerDidCancel(clientPickerViewController: ClientPickerViewController) {
        finish()
    }

    func instructionsViewControllerDidClose(instructionsViewController: InstructionsViewController) {
        finish()
    }
}
