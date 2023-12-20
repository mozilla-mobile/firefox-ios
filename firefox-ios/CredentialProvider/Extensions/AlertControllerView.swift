// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol AlertControllerView {
    func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                title: String?,
                                message: String?,
                                style: UIAlertController.Style,
                                barButtonItem: UIBarButtonItem?)
}

class AlertActionButtonConfiguration {
    let title: String
    let tapAction: () -> Void
    let style: UIAlertAction.Style
    let checked: Bool

    init(title: String, tapAction: @escaping () -> Void, style: UIAlertAction.Style, checked: Bool = false) {
        self.title = title
        self.tapAction = tapAction
        self.style = style
        self.checked = checked
    }
}

extension UIViewController: AlertControllerView {
    func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                title: String?,
                                message: String?,
                                style: UIAlertController.Style,
                                barButtonItem: UIBarButtonItem?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)

        if let barButtonItem = barButtonItem {
            let presentationController = alertController.popoverPresentationController
            presentationController?.barButtonItem = barButtonItem
        }

        for buttonConfig in buttons {
            let action = UIAlertAction(title: buttonConfig.title, style: buttonConfig.style) { _ in
                buttonConfig.tapAction()
            }

            action.setValue(buttonConfig.checked, forKey: "checked")

            alertController.addAction(action)
        }

        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
}
