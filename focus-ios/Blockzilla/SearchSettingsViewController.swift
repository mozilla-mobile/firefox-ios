/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry

protocol SearchSettingsViewControllerDelegate: class {
    func searchSettingsViewController(_ searchSettingsViewController: SearchSettingsViewController, didSelectEngine engine: SearchEngine)
}

class SearchSettingsViewController: UITableViewController {
    weak var delegate: SearchSettingsViewControllerDelegate?

    private let searchEngineManager: SearchEngineManager
    private var isInEditMode = false
    
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
        view.backgroundColor = UIConstants.colors.background
        tableView.separatorColor = UIConstants.colors.settingsSeparator
        tableView.selectRow(at: IndexPath(row: 0, section: 1), animated: false, scrollPosition: .none)
        tableView.tableFooterView = UIView()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: UIConstants.strings.Edit, style: .plain, target: self, action: #selector(SearchSettingsViewController.toggleEditing))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "edit"
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell()
        cell.textLabel?.text = " "
        cell.backgroundColor = UIConstants.colors.background
        
        let label = SmartLabel()
        label.text = UIConstants.strings.InstalledSearchEngines
        label.textColor = UIConstants.colors.tableSectionHeader
        label.font = UIConstants.fonts.tableSectionHeader
        cell.contentView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(cell.textLabel!)
            make.centerY.equalTo(cell.textLabel!).offset(3)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfEngines = searchEngineManager.engines.count
        if isInEditMode { // NOTE: This is false when a user is swiping to delete but tableView.isEditing is true
            return numberOfEngines
        }
        
        return numberOfEngines + 2 // 1 Add search engine row, 1 Restore default search engines row
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let engines = searchEngineManager.engines
        if indexPath.item == engines.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "addSearchEngine")
            cell.textLabel?.text = UIConstants.strings.AddSearchEngineButton
            cell.textLabel?.textColor = UIConstants.colors.settingsTextLabel
            cell.backgroundColor = UIConstants.colors.background
            cell.accessibilityIdentifier = "addSearchEngine"
            cell.selectedBackgroundView = getBackgroundView()
            return cell
        } else if indexPath.item > engines.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "restoreDefaultEngines")
            let label = SmartLabel()
            label.text = UIConstants.strings.RestoreSearchEnginesLabel
            label.font = UIFont.systemFont(ofSize: 17)
            label.textColor = UIConstants.colors.settingsTextLabel
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping

            cell.textLabel?.text = " "
            cell.backgroundColor = UIConstants.colors.background
            cell.accessibilityIdentifier = "restoreDefaults"
            cell.selectedBackgroundView = getBackgroundView()
            cell.addSubview(label)
            label.snp.makeConstraints({ (make) in
                make.topMargin.equalTo(44)
                make.centerY.equalTo(66)
                make.leading.equalTo(cell.textLabel!)
                make.trailing.equalTo(cell.textLabel!)
                make.bottom.equalTo(cell.snp.bottom)
            })
            
            if searchEngineManager.hasDisabledDefaultEngine() {
                label.textColor = UIConstants.colors.settingsTextLabel
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
            } else {
                label.textColor = UIConstants.colors.settingsDisabled
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
            }
            
            return cell
        } else {
            let engine = engines[indexPath.item]
            let cell = UITableViewCell(style: .default, reuseIdentifier: engine.image == nil ? "empty-image-cell" : nil)
            cell.textLabel?.text = engine.name
            cell.textLabel?.textColor = UIConstants.colors.settingsTextLabel
            cell.imageView?.image = engine.image?.createScaled(size: CGSize(width: 24, height: 24))
            cell.selectedBackgroundView = getBackgroundView()
            cell.backgroundColor = UIConstants.colors.background
            cell.accessibilityIdentifier = engine.name
            
            if tableView.isEditing {
                cell.contentView.snp.makeConstraints({ (make) in
                    make.leading.equalTo(0)
                })
                
                cell.imageView?.snp.makeConstraints({ (make) in
                    make.leading.equalTo(50)
                    make.centerY.equalTo(cell)
                })
            }

            if engine === searchEngineManager.activeEngine {
                cell.accessoryType = .checkmark
                
                if tableView.isEditing {
                    cell.textLabel?.textColor = UIConstants.colors.settingsDisabled.withAlphaComponent(0.5)
                    cell.separatorInset = UIEdgeInsetsMake(0, 93, 0, 0)
                    cell.tintColor = tableView.tintColor.withAlphaComponent(0.5)
                    cell.imageView?.alpha = 0.5
                }
            }

            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == searchEngineManager.engines.count+1 ? 44*2 : 44
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let engines = searchEngineManager.engines
        
        if indexPath.item == engines.count {
            // Add search engine tapped
            let vc = AddSearchEngineViewController(delegate: self, searchEngineManager: searchEngineManager)
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.item > engines.count {
            // Restore default engines tapped
            if searchEngineManager.hasDisabledDefaultEngine() {
                searchEngineManager.restoreDisabledDefaultEngines()
                tableView.reloadData()
            }
        } else {
            let engine = engines[indexPath.item]
            searchEngineManager.activeEngine = engine
            Telemetry.default.configuration.defaultSearchEngineProvider = engine.name
            
            _ = navigationController?.popViewController(animated: true)
            delegate?.searchSettingsViewController(self, didSelectEngine: engine)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let engines = searchEngineManager.engines
        
        if indexPath.row >= engines.count {
            // Can not edit the add engine or restore default rows
            return false
        }
        
        let engine = engines[indexPath.row]
        return engine != searchEngineManager.activeEngine
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            searchEngineManager.removeEngine(engine:searchEngineManager.engines[indexPath.row])
            tableView.reloadData()
        }
    }
    
    @objc func toggleEditing() {
        isInEditMode = !isInEditMode
        navigationItem.rightBarButtonItem?.title = tableView.isEditing ? UIConstants.strings.Edit : UIConstants.strings.Done
        tableView.setEditing(!tableView.isEditing, animated: true)
        tableView.reloadData()
        
        navigationItem.hidesBackButton = tableView.isEditing
    }
    
    private func getBackgroundView(bgColor:UIColor = UIConstants.colors.cellSelected) -> UIView {
        let view = UIView()
        view.backgroundColor = bgColor
        return view
    }
}

extension SearchSettingsViewController: AddSearchEngineDelegate {
    func addSearchEngineViewController(_ addSearchEngineViewController: AddSearchEngineViewController, name: String, searchTemplate: String) {
        let engine = searchEngineManager.addEngine(name: name, template: searchTemplate)
        tableView.reloadData()
        delegate?.searchSettingsViewController(self, didSelectEngine: engine)
    }
}
