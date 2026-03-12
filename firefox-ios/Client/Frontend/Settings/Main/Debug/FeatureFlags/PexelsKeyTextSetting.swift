// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A debug setting row for entering a Pexels API key value.
final class PexelsKeyTextSetting: Setting {
    private let keyTitle: String
    private let prefKey: String
    private let onChange: () -> Void

    override var style: UITableViewCell.CellStyle { return .value1 }
    override var status: NSAttributedString? {
        let value = UserDefaults.standard.string(forKey: prefKey) ?? ""
        return NSAttributedString(string: value.isEmpty ? "Not Set" : "Set")
    }

    init(title: String, keyTitle: String, prefKey: String, onChange: @escaping () -> Void) {
        self.keyTitle = keyTitle
        self.prefKey = prefKey
        self.onChange = onChange
        super.init(title: NSAttributedString(string: title))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: keyTitle,
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = "Enter \(self.keyTitle)"
            field.text = UserDefaults.standard.string(forKey: self.prefKey) ?? ""
        }
        let save = UIAlertAction(title: "Save", style: .default) { [weak alert] _ in
            if let value = alert?.textFields?.first?.text, !value.isEmpty {
                UserDefaults.standard.set(value, forKey: self.prefKey)
            }
            self.onChange()
        }
        let clear = UIAlertAction(title: "Clear", style: .destructive) { _ in
            UserDefaults.standard.removeObject(forKey: self.prefKey)
            self.onChange()
        }
        alert.addAction(save)
        alert.addAction(clear)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        navigationController?.present(alert, animated: true)
    }
}
