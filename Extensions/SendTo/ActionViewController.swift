/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import SnapKit

/// The ActionViewController is the initial viewcontroller that is presented (full screen) when the share extension
/// is activated. Depending on whether the user is logged in or not, this viewcontroller will present either the
/// InstructionsVC or the ClientPicker VC.

@objc(ActionViewController)
class ActionViewController: UIViewController, ClientPickerViewControllerDelegate, InstructionsViewControllerDelegate, NonShareableContentViewControllerDelegate
{
    private lazy var profile: Profile = { return BrowserProfile(localName: "profile", app: nil) }()
    private var sharedItem: ShareItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ExtensionUtils.extractSharedItemFromExtensionContext(self.extensionContext, completionHandler: { (item, error) -> Void in
            if let item = item where error == nil && item.isShareable() {
                if !self.profile.hasAccount() {
                    let instructionsViewController = InstructionsViewController()
                    instructionsViewController.delegate = self
                    let navigationController = UINavigationController(rootViewController: instructionsViewController)
                    self.presentViewController(navigationController, animated: false, completion: nil)
                } else {
                    self.sharedItem = item
                    let clientPickerViewController = ClientPickerViewController()
                    clientPickerViewController.clientPickerDelegate = self
                    clientPickerViewController.profile = self.profile
                    let navigationController = UINavigationController(rootViewController: clientPickerViewController)
                    self.presentViewController(navigationController, animated: false, completion: nil)
                }
            } else {
                let vc = NonShareableContentViewController()
                vc.delegate = self
                let navigationController = UINavigationController(rootViewController: vc)
                self.presentViewController(navigationController, animated: false, completion: nil)
            }
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

    func nonShareableContentViewControllerDidClose(nonShareableContentViewController: NonShareableContentViewController) {
        finish()
    }
}

protocol NonShareableContentViewControllerDelegate: class {
    func nonShareableContentViewControllerDidClose(nonShareableContentViewController: NonShareableContentViewController)
}


class NonShareableContentViewController: UIViewController {
    weak var delegate: NonShareableContentViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .None
        view.backgroundColor = UIColor.whiteColor()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", tableName: "SendTo", comment: "Close button in top navigation bar"), style: UIBarButtonItemStyle.Done, target: self, action: #selector(InstructionsViewController.close))
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "NonShareableContentViewController.navigationItem.leftBarButtonItem"

        setupHelpView(view, introText: NSLocalizedString("The link you are trying to share cannot be shared.", tableName: "SendTo", comment: ""),
            showMeText: NSLocalizedString("Only HTTP and HTTPS links can be shared.", tableName: "SendTo", comment: ""))
    }

    func close() {
        delegate?.nonShareableContentViewControllerDidClose(self)
    }
}
