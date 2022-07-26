/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIAlertController {
    static func renameAlertController(currentName: String, renameAction: @escaping (_ newName: String) -> Void, cancelAction: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: UIConstants.strings.renameShortcut, message: nil, preferredStyle: .alert)
        alert.addTextField { textfield in
            textfield.placeholder = UIConstants.strings.renameShortcutAlertPlaceholder
            textfield.text = currentName
            textfield.clearButtonMode = .always
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textfield, queue: OperationQueue.main, using: { _ in
                alert.actions.last?.isEnabled = !(textfield.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false)
            })
        }

        alert.addAction(UIAlertAction(title: UIConstants.strings.renameShortcutAlertSecondaryAction, style: .cancel, handler: { _ in
            cancelAction()
        }))
        alert.addAction(UIAlertAction(title: UIConstants.strings.renameShortcutAlertPrimaryAction, style: .default, handler: { [unowned alert] action in
            let newName = (alert.textFields?.first?.text ?? currentName).trimmingCharacters(in: .whitespacesAndNewlines)
            renameAction(newName)
        }))
        return alert
    }
}
