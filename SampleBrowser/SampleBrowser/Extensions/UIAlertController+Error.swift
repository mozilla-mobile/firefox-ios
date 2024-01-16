// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIAlertController {
    static func showError(errorMessage: String, controller: UIViewController) {
        showMessage(title: "Error", message: errorMessage, controller: controller)
    }

    static func showMessage(title: String, message: String, controller: UIViewController) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let action = UIAlertAction(title: "OK",
                                   style: .default)
        alertController.addAction(action)
        controller.present(alertController, animated: true)
    }
}
