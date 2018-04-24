/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

class SendToDevice: ClientPickerViewControllerDelegate, InstructionsViewControllerDelegate {
    var sharedItem: ShareItem?
    weak var delegate: ShareControllerDelegate?

    func initialViewController() -> UIViewController {
        if !hasAccount() {
            let instructionsViewController = InstructionsViewController()
            instructionsViewController.delegate = self
            return instructionsViewController
        }

        let clientPickerViewController = ClientPickerViewController()
        clientPickerViewController.clientPickerDelegate = self
        clientPickerViewController.profile = nil // This means the picker will open and close the default profile
        return clientPickerViewController
    }

    func finish() {
        delegate?.finish(afterDelay: 0)
    }

    func clientPickerViewController(_ clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient]) {
        guard let item = sharedItem else {
            return finish()
        }

        let profile = BrowserProfile(localName: "profile")
        profile.sendItems([item], toClients: clients).uponQueue(.main) { result in
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
        let profile = BrowserProfile(localName: "profile")
        defer {
            profile.shutdown()
        }
        return profile.hasAccount()
    }
}
