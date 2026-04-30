// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class WorldCupNowOverrideSetting: HiddenSetting {
    private lazy var countdownModel: WorldCupCountdownModel? = {
        guard let prefs = settings.profile?.prefs else { return nil }
        return WorldCupCountdownModel(prefs: prefs)
    }()

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "World Cup: Override 'Now'",
            attributes: [.foregroundColor: theme.colors.textPrimary]
        )
    }

    override var status: NSAttributedString? {
        guard let theme else { return nil }
        let label: String
        if let override = countdownModel?.nowOverride {
            label = "Set to \(DateFormatter.localizedString(from: override, dateStyle: .medium, timeStyle: .short))"
        } else {
            label = "Using real clock"
        }
        return NSAttributedString(
            string: label,
            attributes: [.foregroundColor: theme.colors.textSecondary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: "Override 'Now'",
            message: "Set a fixed date/time for the World Cup countdown.\n\n\n\n\n\n\n\n\n\n\n",
            preferredStyle: .alert
        )

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = countdownModel?.nowOverride ?? Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(datePicker)
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 95)
        ])

        alert.addAction(UIAlertAction(title: "Set", style: .default) { [weak self] _ in
            self?.countdownModel?.nowOverride = datePicker.date
            self?.settings.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Clear (use real clock)", style: .destructive) { [weak self] _ in
            self?.countdownModel?.nowOverride = nil
            self?.settings.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        settings.present(alert, animated: true)
    }
}
