// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// Subclassed to support accessibility identifiers
public class AlertController: UIAlertController {
    private var accessibilityIdentifiers = [UIAlertAction: String]()

    public func addAction(_ action: UIAlertAction, accessibilityIdentifier: String) {
        super.addAction(action)
        accessibilityIdentifiers[action] = accessibilityIdentifier
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // From https://stackoverflow.com/questions/38117410/how-can-i-set-accessibilityidentifier-to-uialertcontroller
        for action in actions {
            let item = action.value(forKey: "__representer") as? UIView
            item?.accessibilityIdentifier = accessibilityIdentifiers[action]
        }
    }
}
