// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import QuickAnswersKit
import Shared

/// Debug setting that overrides which provider model backs Quick Answers,
/// taking precedence over the Nimbus configured model until it is cleared.
final class QuickAnswersModelSetting: HiddenSetting {
    private let prefsKey = PrefsKeys.QuickAnswers.modelOverride
    private var prefs: Prefs? { return settings.profile?.prefs }
    private var overriddenModel: QuickAnswersKit.QuickAnswersModel? {
        guard let rawValue = prefs?.stringForKey(prefsKey) else { return nil }
        return QuickAnswersKit.QuickAnswersModel(rawValue: rawValue)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        let current = overriddenModel?.displayName ?? "Nimbus"
        return NSAttributedString(
            string: "Quick Answers Model: \(current)",
            attributes: [.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(title: "Quick Answers Model",
                                      message: "Overrides the model configured by Nimbus.",
                                      preferredStyle: .alert)
        for model in QuickAnswersKit.QuickAnswersModel.allCases {
            alert.addAction(UIAlertAction(title: model.displayName, style: .default) { [weak self] _ in
                self?.select(model)
            })
        }
        alert.addAction(UIAlertAction(title: "Use Nimbus value", style: .destructive) { [weak self] _ in
            self?.select(nil)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        settings.present(alert, animated: true)
    }

    /// Stores the override, or clears it when `model` is nil so the Nimbus value applies again.
    private func select(_ model: QuickAnswersKit.QuickAnswersModel?) {
        if let model {
            prefs?.setString(model.rawValue, forKey: prefsKey)
        } else {
            prefs?.removeObjectForKey(prefsKey)
        }
        settings.tableView.reloadData()
    }
}
