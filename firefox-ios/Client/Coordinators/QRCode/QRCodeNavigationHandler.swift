// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol QRCodeNavigationHandler: AnyObject {
    /// Shows the QRCodeViewController
    /// The root navigation controller is used when available to present the QRCodeViewController.
    func showQRCode(delegate: QRCodeViewControllerDelegate, rootNavigationController: UINavigationController?)
}

extension QRCodeNavigationHandler {
    func showQRCode(delegate: QRCodeViewControllerDelegate, rootNavigationController: UINavigationController? = nil) {
        showQRCode(delegate: delegate, rootNavigationController: rootNavigationController)
    }
}
