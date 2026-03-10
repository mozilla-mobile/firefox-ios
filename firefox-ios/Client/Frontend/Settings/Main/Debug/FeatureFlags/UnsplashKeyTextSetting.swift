// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit

/// A tappable settings row that lets the user save an Unsplash API key string
/// to UserDefaults via a UIAlertController text field prompt.
final class UnsplashKeyTextSetting: Setting {
    private let keyTitle: String
    private let prefKey: String
    private let onChange: () -> Void

    init(
        title: NSAttributedString,
        keyTitle: String,
        prefKey: String,
        onChange: @escaping () -> Void
    ) {
        self.keyTitle = keyTitle
        self.prefKey = prefKey
        self.onChange = onChange
        super.init(title: title)
    }

    override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: keyTitle,
            message: "Enter the value to save locally for debugging.",
            preferredStyle: .alert
        )
        alert.addTextField { [weak self] textField in
            guard let self else { return }
            textField.placeholder = self.keyTitle
            textField.text = UserDefaults.standard.string(forKey: self.prefKey) ?? ""
            textField.clearButtonMode = .whileEditing
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        let save = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self, let text = alert?.textFields?.first?.text else { return }
            if text.isEmpty {
                UserDefaults.standard.removeObject(forKey: self.prefKey)
            } else {
                UserDefaults.standard.set(text, forKey: self.prefKey)
            }
            self.onChange()
        }
        let clear = UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.removeObject(forKey: self.prefKey)
            self.onChange()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(save)
        alert.addAction(clear)
        alert.addAction(cancel)
        navigationController?.present(alert, animated: true)
    }
}
