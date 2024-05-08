/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol SearchSettingsViewControllerDelegate: AnyObject {
    func searchSettingsViewController(_ searchSettingsViewController: SearchSettingsViewController, didSelectEngine engine: SearchEngine)
}

class SearchSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: SearchSettingsViewControllerDelegate?

    private let searchEngineManager: SearchEngineManager
    private var isInEditMode = false
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.allowsSelection = true
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    init(searchEngineManager: SearchEngineManager) {
        self.searchEngineManager = searchEngineManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = UIConstants.strings.settingsSearchLabel
        navigationController?.navigationBar.tintColor = .accent

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.selectRow(at: IndexPath(row: 0, section: 1), animated: false, scrollPosition: .none)
        tableView.tableFooterView = UIView()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: UIConstants.strings.Edit, style: .plain, target: self, action: #selector(SearchSettingsViewController.toggleEditing))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "edit"
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return UIConstants.strings.InstalledSearchEngines
        } else {
            return nil
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if isInEditMode {
            return 1
        } else {
            return 2
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfEngines = searchEngineManager.engines.count
        if isInEditMode { // NOTE: This is false when a user is swiping to delete but tableView.isEditing is true
            return numberOfEngines
        }
        switch section {
        case 1:
            return 1
        default:
            return numberOfEngines + 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let engines = searchEngineManager.engines
        if indexPath.item == engines.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "addSearchEngine")
            cell.textLabel?.text = UIConstants.strings.AddSearchEngineButton
            cell.textLabel?.textColor = .primaryText
            cell.accessibilityIdentifier = "addSearchEngine"
            cell.selectionStyle = .gray
            return cell
        } else if indexPath.section == 1 && indexPath.row == 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "restoreDefaultEngines")
            cell.textLabel?.text = UIConstants.strings.RestoreSearchEnginesLabel
            cell.textLabel?.font = .body17
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.accessibilityIdentifier = "restoreDefaults"

            if searchEngineManager.hasDisabledDefaultEngine() {
                cell.textLabel?.textColor = .primaryText
                cell.selectionStyle = .gray
                cell.isUserInteractionEnabled = true
            } else {
                cell.textLabel?.textColor = .inputPlaceholder
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
            }

            return cell
        } else {
            let engine = engines[indexPath.item]
            let cell = UITableViewCell(style: .default, reuseIdentifier: engine.image == nil ? "empty-image-cell" : nil)
            cell.textLabel?.text = engine.name
            cell.textLabel?.textColor = .primaryText
            cell.imageView?.image = engine.image?.createScaled(size: CGSize(width: 24, height: 24))
            cell.selectionStyle = .gray
            cell.accessibilityIdentifier = engine.name

            cell.contentView.translatesAutoresizingMaskIntoConstraints = false
            cell.imageView?.translatesAutoresizingMaskIntoConstraints = false
            cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false

            if tableView.isEditing {
                NSLayoutConstraint.activate([
                    cell.contentView.leadingAnchor.constraint(equalTo: cell.leadingAnchor)
                ])

                if let imageView = cell.imageView, let label = cell.textLabel {
                    NSLayoutConstraint.activate([
                        imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: UIConstants.layout.settingsViewOffset),
                        imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                        label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: UIConstants.layout.settingsSearchViewImageOffset),
                        label.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
                    ])
                }
            }

            if engine === searchEngineManager.activeEngine {
                cell.accessoryType = .checkmark

                if tableView.isEditing {
                    cell.textLabel?.textColor = .inputPlaceholder.withAlphaComponent(0.5)
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 93, bottom: 0, right: 0)
                    cell.tintColor = tableView.tintColor.withAlphaComponent(0.5)
                    cell.imageView?.alpha = 0.5
                }
            }

            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == searchEngineManager.engines.count+1 ? 44*2 : 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let engines = searchEngineManager.engines

        if indexPath.item == engines.count {
            // Add search engine tapped
            let vc = AddSearchEngineViewController(delegate: self, searchEngineManager: searchEngineManager)
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 1 {
            // Restore default engines tapped
            if searchEngineManager.hasDisabledDefaultEngine() {
                searchEngineManager.restoreDisabledDefaultEngines()
                tableView.reloadData()
            }
        } else {
            let engine = engines[indexPath.item]
            searchEngineManager.activeEngine = engine

            _ = navigationController?.popViewController(animated: true)
            delegate?.searchSettingsViewController(self, didSelectEngine: engine)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let engines = searchEngineManager.engines

        if indexPath.row >= engines.count {
            // Can not edit the add engine or restore default rows
            return false
        }

        let engine = engines[indexPath.row]
        return engine != searchEngineManager.activeEngine
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.section == 1 ? .none : .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            searchEngineManager.removeEngine(engine: searchEngineManager.engines[indexPath.row])
            tableView.reloadData()
        }
    }

    @objc
    func toggleEditing() {
        isInEditMode = !isInEditMode
        navigationItem.rightBarButtonItem?.title = tableView.isEditing ? UIConstants.strings.Edit : UIConstants.strings.Done
        tableView.setEditing(!tableView.isEditing, animated: true)
        tableView.reloadData()

        navigationItem.hidesBackButton = tableView.isEditing
    }
}

extension SearchSettingsViewController: AddSearchEngineDelegate {
    func addSearchEngineViewController(_ addSearchEngineViewController: AddSearchEngineViewController, name: String, searchTemplate: String) {
        let engine = searchEngineManager.addEngine(name: name, template: searchTemplate)
        tableView.reloadData()
        delegate?.searchSettingsViewController(self, didSelectEngine: engine)
    }
}
