// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import SwiftUI
import UIKit

class SendToDeviceHelper {

    typealias Delegate = InstructionsViewDelegate & DevicePickerViewControllerDelegate

    struct Colors {
        let defaultBackground: UIColor
        let textColor: UIColor
        let iconColor: UIColor
    }

    enum ViewType {
        case instructions
        case picker
    }

    private var profile: Profile
    private var colors: Colors
    private var delegate: Delegate

    init(profile: Profile, colors: Colors, delegate: Delegate) {
        self.profile = profile
        self.colors = colors
        self.delegate = delegate
    }

    func initialViewController() -> UIViewController {
        if !hasAccount() {
            // Display instructions to log in if user has no account
            let instructionsView = InstructionsView(backgroundColor: colors.defaultBackground,
                                                    textColor: colors.textColor,
                                                    imageColor: colors.iconColor,
                                                    dismissAction: {
                self.delegate.dismissInstructionsView()
            })
            let hostingViewController = UIHostingController(rootView: instructionsView)
            let navigationController = UINavigationController(rootViewController: hostingViewController)
            navigationController.modalPresentationStyle = .formSheet
            return navigationController
        }

        // Display device picker if the user has an account
        let devicePickerViewController = DevicePickerViewController()
        devicePickerViewController.pickerDelegate = delegate
        devicePickerViewController.profile = profile
        devicePickerViewController.profileNeedsShutdown = false
//        devicePickerViewController.shareItem = ShareItem
        let navigationController = UINavigationController(rootViewController: devicePickerViewController)
        navigationController.modalPresentationStyle = .formSheet
        return navigationController
    }

    // MARK: - Private
    private func hasAccount() -> Bool {
        return profile.hasAccount()
    }
}
