/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

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
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIConstants.colors.settingsSeparator
        tableView.allowsMultipleSelection = false
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    private var sections: [ThemeSection] {
        let tableSections: [ThemeSection] = currentTheme == .unspecified ? [.systemTheme] : [.systemTheme, .themePicker]
        return tableSections
    }
    
    private var currentTheme: UIUserInterfaceStyle {
        return UserDefaults.standard.theme.userInterfaceStyle
    }
    
    override func viewDidLoad() {
        title = UIConstants.strings.theme
        navigationController?.navigationBar.tintColor = .accent
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    private func configureStyle(for theme: Theme) {
        view.window?.overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
    
    private func configureCell(for indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if sections[indexPath.section] == .systemTheme {
            let themeCell = ThemeTableViewToggleCell(style: .subtitle, reuseIdentifier: "toggleCell")
            themeCell.accessibilityIdentifier = "themeViewController.themetoogleCell"
            (themeCell as ThemeTableViewToggleCell).delegate =  self
            cell = themeCell
        } else {
            let themeCell = ThemeTableViewAccessoryCell(style: .value1, reuseIdentifier: "themeCell")
            themeCell.labelText = indexPath.row == 0 ? UIConstants.strings.light : UIConstants.strings.dark
            themeCell.accessibilityIdentifier = "themeViewController.themeCell"
            let checkmarkImageView = UIImageView(image: UIImage(named: "custom_checkmark"))
            if currentTheme == .light {
                themeCell.accessoryView = indexPath.row == 0 ? checkmarkImageView : .none
            } else if currentTheme == .dark {
                themeCell.accessoryView = indexPath.row == 1 ? checkmarkImageView : .none
            }
            cell = themeCell
        }
        
        cell.backgroundColor = .secondarySystemBackground
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
            if indexPath.row == 0 {
                configureStyle(for: .light)
                UserDefaults.standard.theme = .light
            } else {
                configureStyle(for: .dark)
                UserDefaults.standard.theme = .dark
            }
        default:
            break
        }
        tableView.reloadData()
    }
    
}

extension ThemeViewController: SystemThemeDelegate {
    func didEnableSystemTheme(_ isEnabled: Bool) {
        configureStyle(for: isEnabled ? .device : .light)
        UserDefaults.standard.theme = isEnabled ? .device : .light
        tableView.beginUpdates()
        isEnabled ? tableView.deleteSections([1], with: .fade) :  tableView.insertSections([1], with: .fade)
        tableView.endUpdates()
    }
}
