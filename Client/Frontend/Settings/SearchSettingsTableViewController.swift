/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebImage
import Shared

protocol SearchEnginePickerDelegate: class {
    func searchEnginePicker(_ searchEnginePicker: SearchEnginePicker?, didSelectSearchEngine engine: OpenSearchEngine?)
}

class SearchSettingsTableViewController: UITableViewController {
    fileprivate let SectionDefault = 0
    fileprivate let ItemDefaultEngine = 0
    fileprivate let ItemDefaultSuggestions = 1
    fileprivate let ItemAddCustomSearch = 2
    fileprivate let NumberOfItemsInSectionDefault = 2
    fileprivate let SectionOrder = 1
    fileprivate let NumberOfSections = 2
    fileprivate let IconSize = CGSize(width: OpenSearchEngine.PreferredIconSize, height: OpenSearchEngine.PreferredIconSize)
    fileprivate let SectionHeaderIdentifier = "SectionHeaderIdentifier"
    
    fileprivate var showDeletion = false
    
    var profile: Profile?
    var tabManager: TabManager?

    fileprivate var isEditable: Bool {
        // If the default engine is a custom one, make sure we have more than one since we can't edit the default. 
        // Otherwise, enable editing if we have at least one custom engine.
        let customEngineCount = model.orderedEngines.filter({$0.isCustomEngine}).count
        return model.defaultEngine.isCustomEngine ? customEngineCount > 1 : customEngineCount > 0
    }

    var model: SearchEngines!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search", comment: "Navigation title for search settings.")

        // To allow re-ordering the list of search engines at all times.
        tableView.isEditing = true
        // So that we push the default search engine controller on selection.
        tableView.allowsSelectionDuringEditing = true

        tableView.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier)

        // Insert Done button if being presented outside of the Settings Nav stack
        if !(self.navigationController is SettingsNavigationController) {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.SettingsSearchDoneButton, style: .done, target: self, action: #selector(self.dismissAnimated))
        }

        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.SettingsSearchEditButton, style: .plain, target: self,
                                                                 action: #selector(SearchSettingsTableViewController.beginEditing))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Only show the Edit button if custom search engines are in the list.
        // Otherwise, there is nothing to delete.
        navigationItem.rightBarButtonItem?.isEnabled = isEditable
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setEditing(false, animated: false)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        var engine: OpenSearchEngine!

        if indexPath.section == SectionDefault {
            switch indexPath.item {
            case ItemDefaultEngine:
                engine = model.defaultEngine
                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
                cell.editingAccessoryType = UITableViewCellAccessoryType.disclosureIndicator
                cell.accessibilityLabel = NSLocalizedString("Default Search Engine", comment: "Accessibility label for default search engine setting.")
                cell.accessibilityValue = engine.shortName
                cell.textLabel?.text = engine.shortName
                cell.imageView?.image = engine.image.createScaled(IconSize)
                cell.imageView?.layer.cornerRadius = 4
                cell.imageView?.layer.masksToBounds = true
            case ItemDefaultSuggestions:
                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
                cell.textLabel?.text = NSLocalizedString("Show Search Suggestions", comment: "Label for show search suggestions setting.")
                let toggle = UISwitch()
                toggle.onTintColor = UIConstants.ControlTintColor
                toggle.addTarget(self, action: #selector(SearchSettingsTableViewController.didToggleSearchSuggestions(_:)), for: UIControlEvents.valueChanged)
                toggle.isOn = model.shouldShowSearchSuggestions
                cell.editingAccessoryView = toggle
                cell.selectionStyle = .none
            default:
                // Should not happen.
                break
            }
        } else {
            // The default engine is not a quick search engine.
            let index = indexPath.item + 1
            if index < model.orderedEngines.count {
                engine = model.orderedEngines[index]

                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
                cell.showsReorderControl = true

                let toggle = UISwitch()
                toggle.onTintColor = UIConstants.ControlTintColor
                // This is an easy way to get from the toggle control to the corresponding index.
                toggle.tag = index
                toggle.addTarget(self, action: #selector(SearchSettingsTableViewController.didToggleEngine(_:)), for: UIControlEvents.valueChanged)
                toggle.isOn = model.isEngineEnabled(engine)

                cell.editingAccessoryView = toggle
                cell.textLabel?.text = engine.shortName
                cell.textLabel?.adjustsFontSizeToFitWidth = true
                cell.textLabel?.minimumScaleFactor = 0.5
                cell.imageView?.image = engine.image.createScaled(IconSize)
                cell.imageView?.layer.cornerRadius = 4
                cell.imageView?.layer.masksToBounds = true
                cell.selectionStyle = .none
            } else {
                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
                cell.editingAccessoryType = UITableViewCellAccessoryType.disclosureIndicator
                cell.accessibilityLabel = Strings.SettingsAddCustomEngineTitle
                cell.accessibilityIdentifier = "customEngineViewButton"
                cell.textLabel?.text = Strings.SettingsAddCustomEngine
            }
        }

        // So that the seperator line goes all the way to the left edge.
        cell.separatorInset = UIEdgeInsets.zero

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return NumberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionDefault {
            return NumberOfItemsInSectionDefault
        } else {
            // The first engine -- the default engine -- is not shown in the quick search engine list.
            // But the option to add Custom Engine is.
            return AppConstants.MOZ_CUSTOM_SEARCH_ENGINE ? model.orderedEngines.count : model.orderedEngines.count - 1
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == SectionDefault && indexPath.item == ItemDefaultEngine {
            let searchEnginePicker = SearchEnginePicker()
            // Order alphabetically, so that picker is always consistently ordered.
            // Every engine is a valid choice for the default engine, even the current default engine.
            searchEnginePicker.engines = model.orderedEngines.sorted { e, f in e.shortName < f.shortName }
            searchEnginePicker.delegate = self
            searchEnginePicker.selectedSearchEngineName = model.defaultEngine.shortName
            navigationController?.pushViewController(searchEnginePicker, animated: true)
        } else if indexPath.item + 1 == model.orderedEngines.count {
            let customSearchEngineForm = CustomSearchViewController()
            customSearchEngineForm.profile = self.profile
            navigationController?.pushViewController(customSearchEngineForm, animated: true)
        }
        return nil
    }

    // Don't show delete button on the left.
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == SectionDefault || indexPath.item + 1 == model.orderedEngines.count {
            return UITableViewCellEditingStyle.none
        }

        let index = indexPath.item + 1
        let engine = model.orderedEngines[index]
        return (self.showDeletion && engine.isCustomEngine) ? .delete : .none
    }

    // Don't reserve space for the delete button on the left.
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // Hide a thin vertical line that iOS renders between the accessoryView and the reordering control.
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell.isEditing {
            for v in cell.subviews {
                if v.frame.width == 1.0 {
                    v.backgroundColor = UIColor.clear
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as! SettingsTableSectionHeaderFooterView
        var sectionTitle: String
        if section == SectionDefault {
            sectionTitle = NSLocalizedString("Default Search Engine", comment: "Title for default search engine settings section.")
        } else {
            sectionTitle = NSLocalizedString("Quick-Search Engines", comment: "Title for quick-search engines settings section.")
        }
        headerView.titleLabel.text = sectionTitle

        return headerView
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == SectionDefault || indexPath.item + 1 == model.orderedEngines.count {
            return false
        } else {
            return true
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt indexPath: IndexPath, to newIndexPath: IndexPath) {
        // The first engine (default engine) is not shown in the list, so the indices are off-by-1.
        let index = indexPath.item + 1
        let newIndex = newIndexPath.item + 1
        let engine = model.orderedEngines.remove(at: index)
        model.orderedEngines.insert(engine, at: newIndex)
        tableView.reloadData()
    }

    // Snap to first or last row of the list of engines.
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        // You can't drag or drop on the default engine.
        if sourceIndexPath.section == SectionDefault || proposedDestinationIndexPath.section == SectionDefault {
            return sourceIndexPath
        }

        //Can't drag/drop over "Add Custom Engine button"
        if sourceIndexPath.item + 1 == model.orderedEngines.count || proposedDestinationIndexPath.item + 1 == model.orderedEngines.count {
            return sourceIndexPath
        }

        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            var row = 0
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                row = tableView.numberOfRows(inSection: sourceIndexPath.section) - 1
            }
            return IndexPath(row: row, section: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let index = indexPath.item + 1
            let engine = model.orderedEngines[index]
            model.deleteCustomEngine(engine)
            tableView.deleteRows(at: [indexPath], with: .right)

            // End editing if we are no longer edit since we've deleted all editable cells.
            if !isEditable {
                finishEditing()
            }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        showDeletion = editing
        UIView.performWithoutAnimation {
            self.navigationItem.rightBarButtonItem?.title = editing ? Strings.SettingsSearchDoneButton : Strings.SettingsSearchEditButton
        }
        navigationItem.rightBarButtonItem?.isEnabled = isEditable
        navigationItem.rightBarButtonItem?.action = editing ?
            #selector(SearchSettingsTableViewController.finishEditing) : #selector(SearchSettingsTableViewController.beginEditing)
        tableView.reloadData()
    }
}

// MARK: - Selectors
extension SearchSettingsTableViewController {
    func didToggleEngine(_ toggle: UISwitch) {
        let engine = model.orderedEngines[toggle.tag] // The tag is 1-based.
        if toggle.isOn {
            model.enableEngine(engine)
        } else {
            model.disableEngine(engine)
        }
    }

    func didToggleSearchSuggestions(_ toggle: UISwitch) {
        // Setting the value in settings dismisses any opt-in.
        model.shouldShowSearchSuggestionsOptIn = false
        model.shouldShowSearchSuggestions = toggle.isOn
    }

    func cancel() {
        let _ = navigationController?.popViewController(animated: true)
    }

    func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
    }

    func beginEditing() {
        setEditing(true, animated: false)
    }

    func finishEditing() {
        setEditing(false, animated: false)
    }
}

extension SearchSettingsTableViewController: SearchEnginePickerDelegate {
    func searchEnginePicker(_ searchEnginePicker: SearchEnginePicker?, didSelectSearchEngine searchEngine: OpenSearchEngine?) {
        if let engine = searchEngine {
            model.defaultEngine = engine
            self.tableView.reloadData()
        }
        let _ = navigationController?.popViewController(animated: true)
    }
}
