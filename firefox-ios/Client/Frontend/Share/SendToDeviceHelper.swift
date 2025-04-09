// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
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

    private var shareItem: ShareItem
    private var profile: Profile
    private var colors: Colors
    private weak var delegate: Delegate?

    init(shareItem: ShareItem, profile: Profile, colors: Colors, delegate: Delegate) {
        self.shareItem = shareItem
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
                self.delegate?.dismissInstructionsView()
            })
            let hostingViewController = UIHostingController(rootView: instructionsView)
            #if MOZ_TARGET_SHARETO || MOZ_TARGET_ACTIONEXTENSION
                return hostingViewController
            #else
                let navigationController = UINavigationController(rootViewController: hostingViewController)
                navigationController.modalPresentationStyle = .formSheet
                return navigationController
            #endif
        }

        // Display device picker if the user has an account
        let devicePickerViewController = DevicePickerViewController(profile: profile)
        devicePickerViewController.pickerDelegate = delegate
        devicePickerViewController.shareItem = shareItem
        #if MOZ_TARGET_SHARETO || MOZ_TARGET_ACTIONEXTENSION
        return devicePickerViewController
        #else
        let navigationController = UINavigationController(rootViewController: devicePickerViewController)
        navigationController.modalPresentationStyle = .formSheet
        return navigationController
        #endif
    }

    // MARK: - Private
    private func hasAccount() -> Bool {
        return profile.hasAccount()
    }
}
