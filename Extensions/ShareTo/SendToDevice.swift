// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Storage
import SwiftUI
import UIKit

class SendToDevice: DevicePickerViewControllerDelegate, InstructionsViewDelegate {

    var sharedItem: ShareItem?
    weak var delegate: ShareControllerDelegate?
    private var profile: Profile {
        return BrowserProfile(localName: "profile")
    }

    func initialViewController() -> UIViewController {
        guard let shareItem = sharedItem else {
            finish()
            return UIViewController()
        }

        let colors = SendToDeviceHelper.Colors(defaultBackground: ShareTheme.defaultBackground.color,
                                               textColor: ShareTheme.textColor.color,
                                               iconColor: ShareTheme.iconColor.color)
        let helper = SendToDeviceHelper(shareItem: shareItem,
                                        profile: profile,
                                        colors: colors,
                                        delegate: self)
        let viewController = helper.initialViewController()
        return viewController
    }

    func finish() {
        delegate?.finish(afterDelay: 0)
    }

    func devicePickerViewController(_ devicePickerViewController: DevicePickerViewController, didPickDevices devices: [RemoteDevice]) {
        guard let item = sharedItem else {
            return finish()
        }

        profile.sendItem(item, toDevices: devices).uponQueue(.main) { _ in
            self.profile.shutdown()
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
}
