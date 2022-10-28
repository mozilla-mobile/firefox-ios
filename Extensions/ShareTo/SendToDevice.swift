// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared
import Storage
import SwiftUI

class SendToDevice: DevicePickerViewControllerDelegate, InstructionsViewDelegate {

    var sharedItem: ShareItem?
    weak var delegate: ShareControllerDelegate?

    func initialViewController() -> UIViewController {
        if !hasAccount() {
            let instructionsView = InstructionsView(backgroundColor: ShareTheme.defaultBackground.color,
                                                    textColor: ShareTheme.textColor.color,
                                                    imageColor: ShareTheme.iconColor.color,
                                                    dismissAction: { [weak self] in
                self?.dismissInstructionsView()
            })
            let hostingViewController = UIHostingController(rootView: instructionsView)
            return hostingViewController
        }
        let devicePickerViewController = DevicePickerViewController()
        devicePickerViewController.pickerDelegate = self
        devicePickerViewController.profile = nil // This means the picker will open and close the default profile
        return devicePickerViewController
    }

    func finish() {
        delegate?.finish(afterDelay: 0)
    }

    func devicePickerViewController(_ devicePickerViewController: DevicePickerViewController, didPickDevices devices: [RemoteDevice]) {
        guard let item = sharedItem else {
            return finish()
        }

        let profile = BrowserProfile(localName: "profile")
        profile.sendItem(item, toDevices: devices).uponQueue(.main) { _ in
            profile.shutdown()
            self.finish()

            addAppExtensionTelemetryEvent(forMethod: "send-to-device")
        }
    }

    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController) {
        finish()
    }

    func dismissInstructionsView() {
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
