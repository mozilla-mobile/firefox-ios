/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import UIHelpers

class ThemeViewController: UIViewController {
    enum ThemeSection {
        case systemTheme
        case themePicker

        var numberOfRows: Int {
            switch self {
            case .systemTheme:
                return 1
            case .themePicker:
                return 2
            }
        }

        var name: String {
            switch self {
            case .systemTheme:
                return UIConstants.strings.systemTheme.uppercased()
            case .themePicker:
                return UIConstants.strings.themePicker.uppercased()
            }
        }
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.separatorStyle = .singleLine
        tableView.allowsMultipleSelection = false
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private lazy var tableViewConstraints = [
        tableView.topAnchor.constraint(equalTo: view.topAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ]

    private var sections: [ThemeSection] {
        let tableSections: [ThemeSection] = themeManager.selectedTheme == .unspecified ? [.systemTheme] : [.systemTheme, .themePicker]
        return tableSections
    }

    var themeManager: ThemeManager

    init(themeManager: ThemeManager) {
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = UIConstants.strings.theme
        navigationController?.navigationBar.tintColor = .accent

        view.addSubview(tableView)
        NSLayoutConstraint.activate(tableViewConstraints)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func configureStyle(for theme: ThemeManager.Theme) {
        view.window?.overrideUserInterfaceStyle = theme.userInterfaceStyle
    }

    private func configureCell(for indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if sections[indexPath.section] == .systemTheme {
            let themeCell = ThemeTableViewToggleCell(style: .subtitle, reuseIdentifier: "toggleCell")
            themeCell.accessibilityIdentifier = "themeViewController.themetoogleCell"
            (themeCell as ThemeTableViewToggleCell).delegate =  self
            (themeCell as ThemeTableViewToggleCell).toggle.isOn = themeManager.selectedTheme == .unspecified
            cell = themeCell
        } else {
            let themeCell = ThemeTableViewAccessoryCell(style: .value1, reuseIdentifier: "themeCell")
            themeCell.labelText = indexPath.row == 0 ? UIConstants.strings.light : UIConstants.strings.dark
            themeCell.accessibilityIdentifier = "themeViewController.themeCell"
            let checkmarkImageView = UIImageView(image: UIImage(named: "custom_checkmark"))
            if themeManager.selectedTheme == .light {
                themeCell.accessoryView = indexPath.row == 0 ? checkmarkImageView : .none
            } else if themeManager.selectedTheme == .dark {
                themeCell.accessoryView = indexPath.row == 1 ? checkmarkImageView : .none
            }
            cell = themeCell
        }

        cell.textLabel?.textColor = .primaryText
        cell.layoutMargins = UIEdgeInsets.zero
        cell.detailTextLabel?.textColor = .secondaryText
        cell.textLabel?.setupShrinkage()
        cell.detailTextLabel?.setupShrinkage()

        return cell
    }
}

extension ThemeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return configureCell(for: indexPath)
    }
}

extension ThemeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return  30
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            configureStyle(for: indexPath.row == 0 ? .light : .dark)
            themeManager.set(indexPath.row == 0 ? .light : .dark)
        default:
            break
        }
        tableView.reloadData()
    }
}

extension ThemeViewController: SystemThemeDelegate {
    func didEnableSystemTheme(_ isEnabled: Bool) {
        configureStyle(for: isEnabled ? .device : .light)
        themeManager.set(isEnabled ? .device : .light)
        tableView.beginUpdates()

        if isEnabled {
            tableView.deleteSections([1], with: .fade)
        } else {
            tableView.insertSections([1], with: .fade)
        }

        tableView.endUpdates()
    }
}
