/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SearchSettingsTableViewController: UITableViewController {
    private let SectionDefault = 0

    var model: SearchEngines!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Search", comment: "Settings")

        // Temporary!
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Settings"),
            style: UIBarButtonItemStyle.Done,
            target: navigationController, action: "SELdone")
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        var engine: OpenSearchEngine

        engine = model.defaultEngine
        cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

        cell.textLabel?.text = engine.shortName
        cell.imageView?.image = engine.image

        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionDefault {
            return 1
        }
        return 0
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SectionDefault {
            return NSLocalizedString("Default", comment: "Search Settings")
        }
        return nil
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == SectionDefault {
            let searchEnginePicker = SearchEnginePicker()
            // Order alphabetically, so that picker is always consistently ordered.
            searchEnginePicker.engines = model.orderedEngines.sorted { e, f in e.shortName < f.shortName }
            searchEnginePicker.delegate = self
            navigationController?.pushViewController(searchEnginePicker, animated: true)
        }
        return nil
    }

    func SELcancel() {
        navigationController?.popViewControllerAnimated(true)
    }
}

extension SearchSettingsTableViewController: SearchEnginePickerDelegate {
    func searchEnginePicker(searchEnginePicker: SearchEnginePicker, didSelectSearchEngine searchEngine: OpenSearchEngine?) {
        if let engine = searchEngine {
            model.defaultEngine = engine
            self.tableView.reloadData()
        }
        navigationController?.popViewControllerAnimated(true)
    }
}
